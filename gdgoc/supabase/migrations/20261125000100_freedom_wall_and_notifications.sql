-- ============================================================================
-- Freedom Wall - Supabase / PostgreSQL migration
--
-- EXPECTED EXISTING PROFILES TABLE:
--   public.profiles.profile_id UUID PRIMARY KEY (or UNIQUE)
--   public.profiles.display_name TEXT
--
-- EXPECTED AUTH LINK:
--   profiles.profile_id must equal auth.users.id (auth.uid()).
--
-- If your profiles table uses different names or data types, adjust the
-- references to profile_id and display_name before running this migration.
-- This migration does NOT create or modify public.profiles.
--
-- Apply this file once using the Supabase SQL Editor or Supabase CLI.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. ENUMS
-- ---------------------------------------------------------------------------

CREATE TYPE public.freedom_wall_topic AS ENUM (
    'general',
    'project_collaboration',
    'tech_tips',
    'hackathon',
    'shoutout',
    'questions'
);

CREATE TYPE public.freedom_wall_submission_status AS ENUM (
    'pending',
    'approved',
    'rejected'
);

CREATE TYPE public.freedom_wall_reaction_type AS ENUM (
    'love',
    'ship_it',
    'lit',
    'relatable',
    'tech'
);

CREATE TYPE public.freedom_wall_moderation_action AS ENUM (
    'approve',
    'reject',
    'edit',
    'admin_delete',
    'member_delete'
);

-- ---------------------------------------------------------------------------
-- 2. TABLES
-- ---------------------------------------------------------------------------

-- One row represents one submission throughout its entire lifecycle.
-- A submission becomes a public post when status changes to 'approved'.
CREATE TABLE public.freedom_wall_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    author_id UUID NOT NULL
        REFERENCES public.profiles(profile_id) ON DELETE CASCADE,

    message TEXT NOT NULL,
    topic public.freedom_wall_topic NOT NULL,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    status public.freedom_wall_submission_status NOT NULL DEFAULT 'pending',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    rejection_reason TEXT,

    CONSTRAINT freedom_wall_message_length_and_content CHECK (
        char_length(message) <= 2000
        AND char_length(btrim(message)) > 0
    ),

    -- Keep the timestamps/reason consistent with the status.
    CONSTRAINT freedom_wall_status_fields_consistent CHECK (
        (
            status = 'pending'
            AND approved_at IS NULL
            AND rejected_at IS NULL
            AND rejection_reason IS NULL
        )
        OR
        (
            status = 'approved'
            AND approved_at IS NOT NULL
            AND rejected_at IS NULL
            AND rejection_reason IS NULL
        )
        OR
        (
            status = 'rejected'
            AND approved_at IS NULL
            AND rejected_at IS NOT NULL
            AND NULLIF(BTRIM(rejection_reason), '') IS NOT NULL
        )
    )
);

COMMENT ON TABLE public.freedom_wall_submissions IS
'All Freedom Wall submissions. Approved rows are the public posts; no separate posts table is needed.';

COMMENT ON COLUMN public.freedom_wall_submissions.author_id IS
'Always stores the real submitter profile, including for anonymous submissions. Do not expose this field through public APIs.';

-- A member may have at most one pending submission at a time.
CREATE UNIQUE INDEX freedom_wall_one_pending_per_member
    ON public.freedom_wall_submissions (author_id)
    WHERE status = 'pending';

CREATE INDEX freedom_wall_submissions_author_created_idx
    ON public.freedom_wall_submissions (author_id, created_at DESC);

CREATE INDEX freedom_wall_submissions_approved_at_idx
    ON public.freedom_wall_submissions (approved_at DESC)
    WHERE status = 'approved';

CREATE INDEX freedom_wall_submissions_rejected_at_idx
    ON public.freedom_wall_submissions (rejected_at)
    WHERE status = 'rejected';

-- Used by the public feed's keyword search RPC.
CREATE INDEX freedom_wall_submissions_message_search_idx
    ON public.freedom_wall_submissions
    USING GIN (to_tsvector('simple', message))
    WHERE status = 'approved';

-- One reaction per member per submission. A member can change their reaction.
CREATE TABLE public.freedom_wall_reactions (
    submission_id UUID NOT NULL
        REFERENCES public.freedom_wall_submissions(id) ON DELETE CASCADE,

    user_id UUID NOT NULL
        REFERENCES public.profiles(profile_id) ON DELETE CASCADE,

    reaction_type public.freedom_wall_reaction_type NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT freedom_wall_one_reaction_per_user
        PRIMARY KEY (submission_id, user_id)
);

CREATE INDEX freedom_wall_reactions_user_idx
    ON public.freedom_wall_reactions (user_id);

-- Audit history. submission_id intentionally has NO foreign key so the log
-- can retain the original UUID after a submission is deleted/purged.
CREATE TABLE public.freedom_wall_moderation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL,
    actor_id UUID
        REFERENCES public.profiles(profile_id) ON DELETE SET NULL,
    action public.freedom_wall_moderation_action NOT NULL,
    reason TEXT,
    details JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX freedom_wall_moderation_logs_submission_idx
    ON public.freedom_wall_moderation_logs (submission_id, created_at DESC);

CREATE INDEX freedom_wall_moderation_logs_actor_idx
    ON public.freedom_wall_moderation_logs (actor_id, created_at DESC);

-- Admin allow-list for this feature. Add/remove rows using the SQL Editor.
-- This avoids assuming that your existing profiles table has a particular
-- admin/role column.
CREATE TABLE public.freedom_wall_admins (
    profile_id UUID PRIMARY KEY
        REFERENCES public.profiles(profile_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Generic per-user inbox. It is NOT Freedom Wall-specific.
-- Examples of category values: 'freedom_wall', 'announcement', 'event', 'system'.
-- reference_type/reference_id are intentionally polymorphic; they can refer to
-- records in different feature tables, so there is no single FK for reference_id.
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    recipient_id UUID NOT NULL
        REFERENCES public.profiles(profile_id) ON DELETE CASCADE,

    category TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,

    action_url TEXT,
    reference_type TEXT,
    reference_id UUID,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    read_at TIMESTAMPTZ,

    CONSTRAINT notifications_category_not_empty
        CHECK (char_length(btrim(category)) > 0),
    CONSTRAINT notifications_title_not_empty
        CHECK (char_length(btrim(title)) > 0),
    CONSTRAINT notifications_body_not_empty
        CHECK (char_length(btrim(body)) > 0)
);

CREATE INDEX notifications_recipient_created_idx
    ON public.notifications (recipient_id, created_at DESC);

CREATE INDEX notifications_recipient_unread_idx
    ON public.notifications (recipient_id, created_at DESC)
    WHERE read_at IS NULL;

-- ---------------------------------------------------------------------------
-- 3. PRIVATE HELPERS AND TRIGGERS
-- ---------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;

-- Used only by trusted database functions to verify an admin.
CREATE OR REPLACE FUNCTION private.is_freedom_wall_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.freedom_wall_admins AS a
        WHERE a.profile_id = (SELECT auth.uid())
    );
$$;

REVOKE ALL ON FUNCTION private.is_freedom_wall_admin() FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER freedom_wall_submissions_set_updated_at
BEFORE UPDATE ON public.freedom_wall_submissions
FOR EACH ROW
EXECUTE FUNCTION private.set_updated_at();

-- ---------------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY AND TABLE PRIVILEGES
-- ---------------------------------------------------------------------------

ALTER TABLE public.freedom_wall_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.freedom_wall_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.freedom_wall_moderation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.freedom_wall_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- No direct client access to the core Freedom Wall tables. Clients use the
-- RPC functions below. This prevents clients from selecting author_id or
-- changing moderation status directly.
REVOKE ALL ON TABLE public.freedom_wall_submissions FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.freedom_wall_reactions FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.freedom_wall_moderation_logs FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.freedom_wall_admins FROM PUBLIC, anon, authenticated;

-- Notifications are shared by multiple app features. A signed-in user can
-- read their own inbox and update only read_at (not title/body/recipient).
REVOKE ALL ON TABLE public.notifications FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.notifications TO authenticated;
GRANT UPDATE (read_at) ON TABLE public.notifications TO authenticated;

CREATE POLICY notifications_select_own
ON public.notifications
FOR SELECT
TO authenticated
USING (recipient_id = (SELECT auth.uid()));

CREATE POLICY notifications_mark_own_read
ON public.notifications
FOR UPDATE
TO authenticated
USING (recipient_id = (SELECT auth.uid()))
WITH CHECK (recipient_id = (SELECT auth.uid()));

-- The service_role can create notifications for announcements/events and
-- other trusted backend workflows. Never expose its key in a browser.
GRANT ALL ON TABLE public.notifications TO service_role;

-- ---------------------------------------------------------------------------
-- 5. MEMBER RPC FUNCTIONS
-- ---------------------------------------------------------------------------

-- Public feed: returns ONLY approved submissions and safe display fields.
-- It deliberately does NOT return author_id or is_anonymous.
CREATE OR REPLACE FUNCTION public.list_freedom_wall_posts(
    p_topic public.freedom_wall_topic DEFAULT NULL,
    p_search TEXT DEFAULT NULL,
    p_sort TEXT DEFAULT 'newest',
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    submission_id UUID,
    author_label TEXT,
    topic public.freedom_wall_topic,
    message TEXT,
    published_at TIMESTAMPTZ,
    love_count BIGINT,
    ship_it_count BIGINT,
    lit_count BIGINT,
    relatable_count BIGINT,
    tech_count BIGINT,
    total_reactions BIGINT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_sort TEXT := LOWER(COALESCE(p_sort, 'newest'));
    v_limit INTEGER := LEAST(GREATEST(COALESCE(p_limit, 20), 1), 100);
    v_offset INTEGER := GREATEST(COALESCE(p_offset, 0), 0);
BEGIN
    IF v_sort NOT IN ('newest', 'popular') THEN
        RAISE EXCEPTION 'Sort must be either newest or popular.';
    END IF;

    RETURN QUERY
    SELECT
        s.id AS submission_id,
        CASE
            WHEN s.is_anonymous THEN 'Anonymous'
            ELSE COALESCE(p.display_name, 'Member')
        END AS author_label,
        s.topic,
        s.message,
        s.approved_at AS published_at,
        COALESCE(r.love_count, 0)::BIGINT,
        COALESCE(r.ship_it_count, 0)::BIGINT,
        COALESCE(r.lit_count, 0)::BIGINT,
        COALESCE(r.relatable_count, 0)::BIGINT,
        COALESCE(r.tech_count, 0)::BIGINT,
        (
            COALESCE(r.love_count, 0)
            + COALESCE(r.ship_it_count, 0)
            + COALESCE(r.lit_count, 0)
            + COALESCE(r.relatable_count, 0)
            + COALESCE(r.tech_count, 0)
        )::BIGINT AS total_reactions
    FROM public.freedom_wall_submissions AS s
    LEFT JOIN public.profiles AS p
        ON p.profile_id = s.author_id
    LEFT JOIN LATERAL (
        SELECT
            COUNT(*) FILTER (WHERE x.reaction_type = 'love') AS love_count,
            COUNT(*) FILTER (WHERE x.reaction_type = 'ship_it') AS ship_it_count,
            COUNT(*) FILTER (WHERE x.reaction_type = 'lit') AS lit_count,
            COUNT(*) FILTER (WHERE x.reaction_type = 'relatable') AS relatable_count,
            COUNT(*) FILTER (WHERE x.reaction_type = 'tech') AS tech_count
        FROM public.freedom_wall_reactions AS x
        WHERE x.submission_id = s.id
    ) AS r ON TRUE
    WHERE s.status = 'approved'
      AND (p_topic IS NULL OR s.topic = p_topic)
      AND (
          NULLIF(BTRIM(p_search), '') IS NULL
          OR to_tsvector('simple', s.message)
             @@ plainto_tsquery('simple', p_search)
      )
    ORDER BY
        CASE WHEN v_sort = 'popular' THEN
            COALESCE(r.love_count, 0)
            + COALESCE(r.ship_it_count, 0)
            + COALESCE(r.lit_count, 0)
            + COALESCE(r.relatable_count, 0)
            + COALESCE(r.tech_count, 0)
        END DESC NULLS LAST,
        s.approved_at DESC,
        s.id DESC
    LIMIT v_limit
    OFFSET v_offset;
END;
$$;

-- Submitter's own history, including pending/rejected status and rejection reason.
CREATE OR REPLACE FUNCTION public.get_my_freedom_wall_submissions()
RETURNS TABLE (
    submission_id UUID,
    message TEXT,
    topic public.freedom_wall_topic,
    is_anonymous BOOLEAN,
    status public.freedom_wall_submission_status,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    rejection_reason TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF (SELECT auth.uid()) IS NULL THEN
        RAISE EXCEPTION 'You must be signed in to view your submissions.';
    END IF;

    RETURN QUERY
    SELECT
        s.id,
        s.message,
        s.topic,
        s.is_anonymous,
        s.status,
        s.created_at,
        s.updated_at,
        s.approved_at,
        s.rejected_at,
        s.rejection_reason
    FROM public.freedom_wall_submissions AS s
    WHERE s.author_id = (SELECT auth.uid())
    ORDER BY s.created_at DESC;
END;
$$;

-- Create a submission. The partial unique index enforces one pending row/member.
CREATE OR REPLACE FUNCTION public.create_freedom_wall_submission(
    p_message TEXT,
    p_topic public.freedom_wall_topic,
    p_is_anonymous BOOLEAN DEFAULT FALSE
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID := (SELECT auth.uid());
    v_submission_id UUID;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'You must be signed in to submit a post.';
    END IF;

    IF p_message IS NULL
       OR char_length(p_message) > 2000
       OR char_length(btrim(p_message)) = 0 THEN
        RAISE EXCEPTION 'Message must contain 1 to 2000 non-whitespace characters.';
    END IF;

    IF p_topic IS NULL THEN
        RAISE EXCEPTION 'A topic is required.';
    END IF;

    INSERT INTO public.freedom_wall_submissions (
        author_id, message, topic, is_anonymous
    )
    VALUES (
        v_user_id, p_message, p_topic, COALESCE(p_is_anonymous, FALSE)
    )
    RETURNING id INTO v_submission_id;

    RETURN v_submission_id;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'You already have a pending Freedom Wall submission. Wait for it to be reviewed before submitting another.'
            USING ERRCODE = '23505';
END;
$$;

-- Delete any of the caller's own submissions, regardless of status.
CREATE OR REPLACE FUNCTION public.delete_my_freedom_wall_submission(
    p_submission_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_status public.freedom_wall_submission_status;
BEGIN
    IF (SELECT auth.uid()) IS NULL THEN
        RAISE EXCEPTION 'You must be signed in.';
    END IF;

    SELECT s.status
    INTO v_status
    FROM public.freedom_wall_submissions AS s
    WHERE s.id = p_submission_id
      AND s.author_id = (SELECT auth.uid())
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    INSERT INTO public.freedom_wall_moderation_logs (
        submission_id, actor_id, action, details
    )
    VALUES (
        p_submission_id,
        (SELECT auth.uid()),
        'member_delete',
        jsonb_build_object(
            'deleted_submission_id', p_submission_id,
            'previous_status', v_status
        )
    );

    DELETE FROM public.freedom_wall_submissions
    WHERE id = p_submission_id
      AND author_id = (SELECT auth.uid());

    RETURN TRUE;
END;
$$;

-- Set or change the caller's reaction on an approved post.
CREATE OR REPLACE FUNCTION public.set_freedom_wall_reaction(
    p_submission_id UUID,
    p_reaction_type public.freedom_wall_reaction_type
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF (SELECT auth.uid()) IS NULL THEN
        RAISE EXCEPTION 'You must be signed in to react.';
    END IF;

    IF p_reaction_type IS NULL THEN
        RAISE EXCEPTION 'A reaction type is required.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.freedom_wall_submissions AS s
        WHERE s.id = p_submission_id
          AND s.status = 'approved'
    ) THEN
        RAISE EXCEPTION 'This post does not exist or is not published.';
    END IF;

    INSERT INTO public.freedom_wall_reactions (
        submission_id, user_id, reaction_type
    )
    VALUES (
        p_submission_id, (SELECT auth.uid()), p_reaction_type
    )
    ON CONFLICT (submission_id, user_id)
    DO UPDATE SET
        reaction_type = EXCLUDED.reaction_type,
        created_at = NOW();
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_my_freedom_wall_reaction(
    p_submission_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    IF (SELECT auth.uid()) IS NULL THEN
        RAISE EXCEPTION 'You must be signed in.';
    END IF;

    DELETE FROM public.freedom_wall_reactions
    WHERE submission_id = p_submission_id
      AND user_id = (SELECT auth.uid());

    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count > 0;
END;
$$;

-- ---------------------------------------------------------------------------
-- 6. ADMIN RPC FUNCTIONS
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.admin_list_freedom_wall_submissions(
    p_status public.freedom_wall_submission_status DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    submission_id UUID,
    author_id UUID,
    author_display_name TEXT,
    author_email TEXT,
    message TEXT,
    topic public.freedom_wall_topic,
    is_anonymous BOOLEAN,
    status public.freedom_wall_submission_status,
    created_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    rejection_reason TEXT,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT private.is_freedom_wall_admin() THEN
        RAISE EXCEPTION 'Administrator access required.';
    END IF;

    RETURN QUERY
    SELECT
        s.id,
        s.author_id,
        COALESCE(p.display_name, 'Member'),
        u.email,
        s.message,
        s.topic,
        s.is_anonymous,
        s.status,
        s.created_at,
        s.approved_at,
        s.rejected_at,
        s.rejection_reason,
        s.updated_at
    FROM public.freedom_wall_submissions AS s
    LEFT JOIN public.profiles AS p
        ON p.profile_id = s.author_id
    LEFT JOIN auth.users AS u
        ON u.id = s.author_id
    WHERE p_status IS NULL OR s.status = p_status
    ORDER BY s.created_at DESC
    LIMIT LEAST(GREATEST(COALESCE(p_limit, 50), 1), 200)
    OFFSET GREATEST(COALESCE(p_offset, 0), 0);
END;
$$;

-- Moderation audit history, including records whose submissions were later deleted.
CREATE OR REPLACE FUNCTION public.admin_list_freedom_wall_moderation_logs(
    p_submission_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    log_id UUID,
    submission_id UUID,
    moderator_id UUID,
    moderator_display_name TEXT,
    action public.freedom_wall_moderation_action,
    reason TEXT,
    details JSONB,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT private.is_freedom_wall_admin() THEN
        RAISE EXCEPTION 'Administrator access required.';
    END IF;

    RETURN QUERY
    SELECT
        l.id,
        l.submission_id,
        l.actor_id,
        COALESCE(p.display_name, 'Former member'),
        l.action,
        l.reason,
        l.details,
        l.created_at
    FROM public.freedom_wall_moderation_logs AS l
    LEFT JOIN public.profiles AS p
        ON p.profile_id = l.actor_id
    WHERE p_submission_id IS NULL OR l.submission_id = p_submission_id
    ORDER BY l.created_at DESC
    LIMIT LEAST(GREATEST(COALESCE(p_limit, 100), 1), 500)
    OFFSET GREATEST(COALESCE(p_offset, 0), 0);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_approve_freedom_wall_submission(
    p_submission_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_author_id UUID;
BEGIN
    IF NOT private.is_freedom_wall_admin() THEN
        RAISE EXCEPTION 'Administrator access required.';
    END IF;

    UPDATE public.freedom_wall_submissions AS s
    SET status = 'approved',
        approved_at = NOW(),
        rejected_at = NULL,
        rejection_reason = NULL
    WHERE s.id = p_submission_id
      AND s.status = 'pending'
    RETURNING s.author_id INTO v_author_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Submission not found or is no longer pending.';
    END IF;

    INSERT INTO public.freedom_wall_moderation_logs (
        submission_id, actor_id, action, details
    )
    VALUES (
        p_submission_id,
        (SELECT auth.uid()),
        'approve',
        jsonb_build_object('submission_id', p_submission_id)
    );

    INSERT INTO public.notifications (
        recipient_id, category, title, body,
        action_url, reference_type, reference_id, metadata
    )
    VALUES (
        v_author_id,
        'freedom_wall',
        'Your Freedom Wall post was approved',
        'Your submission has been approved and is now visible on the Freedom Wall.',
        '/freedom-wall/submissions/' || p_submission_id::TEXT,
        'freedom_wall_submission',
        p_submission_id,
        jsonb_build_object('status', 'approved')
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_reject_freedom_wall_submission(
    p_submission_id UUID,
    p_rejection_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_author_id UUID;
    v_reason TEXT := NULLIF(BTRIM(p_rejection_reason), '');
BEGIN
    IF NOT private.is_freedom_wall_admin() THEN
        RAISE EXCEPTION 'Administrator access required.';
    END IF;

    IF v_reason IS NULL THEN
        RAISE EXCEPTION 'A rejection reason is required.';
    END IF;

    UPDATE public.freedom_wall_submissions AS s
    SET status = 'rejected',
        approved_at = NULL,
        rejected_at = NOW(),
        rejection_reason = v_reason
    WHERE s.id = p_submission_id
      AND s.status = 'pending'
    RETURNING s.author_id INTO v_author_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Submission not found or is no longer pending.';
    END IF;

    INSERT INTO public.freedom_wall_moderation_logs (
        submission_id, actor_id, action, reason, details
    )
    VALUES (
        p_submission_id,
        (SELECT auth.uid()),
        'reject',
        v_reason,
        jsonb_build_object('submission_id', p_submission_id)
    );

    INSERT INTO public.notifications (
        recipient_id, category, title, body,
        action_url, reference_type, reference_id, metadata
    )
    VALUES (
        v_author_id,
        'freedom_wall',
        'Your Freedom Wall post was rejected',
        'Your submission was not approved. Reason: ' || v_reason,
        '/freedom-wall/my-submissions',
        'freedom_wall_submission',
        p_submission_id,
        jsonb_build_object('status', 'rejected', 'rejection_reason', v_reason)
    );
END;
$$;

-- Edit content/topic without changing the original author or anonymity setting.
CREATE OR REPLACE FUNCTION public.admin_edit_freedom_wall_submission(
    p_submission_id UUID,
    p_new_message TEXT,
    p_new_topic public.freedom_wall_topic
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_old_message TEXT;
    v_old_topic public.freedom_wall_topic;
BEGIN
    IF NOT private.is_freedom_wall_admin() THEN
        RAISE EXCEPTION 'Administrator access required.';
    END IF;

    SELECT s.message, s.topic
    INTO v_old_message, v_old_topic
    FROM public.freedom_wall_submissions AS s
    WHERE s.id = p_submission_id
      AND s.status = 'approved'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Approved submission not found.';
    END IF;

    IF p_new_message IS NULL
       OR char_length(p_new_message) > 2000
       OR char_length(btrim(p_new_message)) = 0 THEN
        RAISE EXCEPTION 'Message must contain 1 to 2000 non-whitespace characters.';
    END IF;

    IF p_new_topic IS NULL THEN
        RAISE EXCEPTION 'A topic is required.';
    END IF;

    UPDATE public.freedom_wall_submissions
    SET message = p_new_message,
        topic = p_new_topic
    WHERE id = p_submission_id;

    INSERT INTO public.freedom_wall_moderation_logs (
        submission_id, actor_id, action, details
    )
    VALUES (
        p_submission_id,
        (SELECT auth.uid()),
        'edit',
        jsonb_build_object(
            'old_message', v_old_message,
            'new_message', p_new_message,
            'old_topic', v_old_topic,
            'new_topic', p_new_topic
        )
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_freedom_wall_submission(
    p_submission_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_submission public.freedom_wall_submissions%ROWTYPE;
BEGIN
    IF NOT private.is_freedom_wall_admin() THEN
        RAISE EXCEPTION 'Administrator access required.';
    END IF;

    SELECT * INTO v_submission
    FROM public.freedom_wall_submissions AS s
    WHERE s.id = p_submission_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Keep an audit snapshot even though the actual submission is deleted.
    INSERT INTO public.freedom_wall_moderation_logs (
        submission_id, actor_id, action, details
    )
    VALUES (
        p_submission_id,
        (SELECT auth.uid()),
        'admin_delete',
        jsonb_build_object(
            'deleted_submission_id', v_submission.id,
            'author_id', v_submission.author_id,
            'previous_status', v_submission.status,
            'message', v_submission.message,
            'topic', v_submission.topic,
            'is_anonymous', v_submission.is_anonymous
        )
    );

    DELETE FROM public.freedom_wall_submissions
    WHERE id = p_submission_id;

    RETURN TRUE;
END;
$$;

-- ---------------------------------------------------------------------------
-- 7. NOTIFICATION RPC
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.mark_notification_read(
    p_notification_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_rows INTEGER;
BEGIN
    IF (SELECT auth.uid()) IS NULL THEN
        RAISE EXCEPTION 'You must be signed in.';
    END IF;

    UPDATE public.notifications
    SET read_at = COALESCE(read_at, NOW())
    WHERE id = p_notification_id
      AND recipient_id = (SELECT auth.uid());

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN v_rows > 0;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_rows INTEGER;
BEGIN
    IF (SELECT auth.uid()) IS NULL THEN
        RAISE EXCEPTION 'You must be signed in.';
    END IF;

    UPDATE public.notifications
    SET read_at = NOW()
    WHERE recipient_id = (SELECT auth.uid())
      AND read_at IS NULL;

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN v_rows;
END;
$$;

-- ---------------------------------------------------------------------------
-- 8. RPC EXECUTE PRIVILEGES
-- ---------------------------------------------------------------------------

-- Remove PostgreSQL's default PUBLIC execute permission from these functions.
REVOKE ALL ON FUNCTION public.list_freedom_wall_posts(
    public.freedom_wall_topic, TEXT, TEXT, INTEGER, INTEGER
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_freedom_wall_submissions() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_freedom_wall_submission(
    TEXT, public.freedom_wall_topic, BOOLEAN
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_my_freedom_wall_submission(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.set_freedom_wall_reaction(
    UUID, public.freedom_wall_reaction_type
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.remove_my_freedom_wall_reaction(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_list_freedom_wall_submissions(
    public.freedom_wall_submission_status, INTEGER, INTEGER
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_list_freedom_wall_moderation_logs(UUID, INTEGER, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_approve_freedom_wall_submission(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_reject_freedom_wall_submission(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_edit_freedom_wall_submission(
    UUID, TEXT, public.freedom_wall_topic
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_delete_freedom_wall_submission(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_notification_read(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_all_notifications_read() FROM PUBLIC;

-- Public feed can be called by visitors and signed-in members.
GRANT EXECUTE ON FUNCTION public.list_freedom_wall_posts(
    public.freedom_wall_topic, TEXT, TEXT, INTEGER, INTEGER
) TO anon, authenticated;

-- Member operations require authentication. Admin RPCs also check the allow-list.
GRANT EXECUTE ON FUNCTION public.get_my_freedom_wall_submissions() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_freedom_wall_submission(
    TEXT, public.freedom_wall_topic, BOOLEAN
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_my_freedom_wall_submission(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_freedom_wall_reaction(
    UUID, public.freedom_wall_reaction_type
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_my_freedom_wall_reaction(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_freedom_wall_submissions(
    public.freedom_wall_submission_status, INTEGER, INTEGER
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_freedom_wall_moderation_logs(UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_approve_freedom_wall_submission(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_reject_freedom_wall_submission(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_edit_freedom_wall_submission(
    UUID, TEXT, public.freedom_wall_topic
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_freedom_wall_submission(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_notification_read(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read() TO authenticated;

COMMIT;

-- ---------------------------------------------------------------------------
-- 9. SUPABASE CRON: DELETE REJECTED SUBMISSIONS AFTER 30 DAYS
-- ---------------------------------------------------------------------------
-- Supabase Cron uses pg_cron. Enable it if it is not already enabled.
-- The hourly job deletes rows once rejected_at is at least 30 days old.
-- Related reactions are deleted by ON DELETE CASCADE. Notifications remain;
-- their reference_id is informational and does not have a foreign key.
-- Moderation logs also remain as audit history.

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;

SELECT cron.schedule(
    'freedom-wall-delete-expired-rejections',
    '0 * * * *',
    $cron$
        DELETE FROM public.freedom_wall_submissions
        WHERE status = 'rejected'
          AND rejected_at <= NOW() - INTERVAL '30 days';
    $cron$
);

-- ---------------------------------------------------------------------------
-- 10. FIRST ADMIN SETUP (RUN MANUALLY AFTER THE MIGRATION)
-- ---------------------------------------------------------------------------
-- Replace the UUID below with the profile_id/auth.users.id of an administrator.
-- Run this separately in the Supabase SQL Editor:
--
-- INSERT INTO public.freedom_wall_admins (profile_id)
-- VALUES ('00000000-0000-0000-0000-000000000000');
--
-- To remove an administrator:
-- DELETE FROM public.freedom_wall_admins
-- WHERE profile_id = '00000000-0000-0000-0000-000000000000';
--
-- Only trusted project administrators should be able to edit this allow-list.
