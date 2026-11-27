-- Administrators: the Users baseline and the Administrator check.
--
-- See docs/adr/0001-supabase-as-cms.md and docs/adr/0003-one-supabase-project.md.
-- Every CMS table checks private.is_admin() in its RLS policies, so the
-- Administrator flag (Users.is_admin) must be impossible for a Member to set.

-- ---------------------------------------------------------------------------
-- Users baseline.
-- The production table predates this repo and its exact structure was never
-- recorded. This recreates it from the columns the app uses, so a local or
-- rebuilt database works. "if not exists" leaves an existing table alone.
--
-- Production assumptions (check them in the dashboard before applying this
-- to the live project; the Supabase project is being recreated, PRD §5.5):
--   * Existing policies on "Users" are unknown. Permissive policies are OR'd
--     together, so an older broad one (for example "anyone can select") would
--     quietly override the ones below. This migration therefore drops every
--     policy on "Users" before creating its own (see below). Dump them first.
--   * No two rows share a gdg_id, or adding its unique constraint fails.
-- ---------------------------------------------------------------------------
create table if not exists public."Users" (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  first_name text not null,
  last_name  text not null,
  gdg_id     text,
  email      text not null,
  campus     text,
  is_admin   boolean not null default false,
  created_at timestamptz not null default now()
);

-- An existing table was kept as it is, so stop here if it lacks a column this
-- file or the app uses, instead of failing later at runtime.
do $$
declare
  problems text;
begin
  select string_agg(required.column_name || coalesce(' (must be ' || required.data_type || ')', ''), ', ')
    into problems
  from (values
    ('user_id', null), ('first_name', null), ('last_name', null), ('gdg_id', null),
    ('email', null), ('campus', null), ('is_admin', 'boolean')
  ) as required(column_name, data_type)
  where not exists (
    select 1 from information_schema.columns c
    where c.table_schema = 'public' and c.table_name = 'Users'
      and c.column_name = required.column_name
      and c.data_type = coalesce(required.data_type, c.data_type)
  );

  if problems is not null then
    raise exception 'The existing public."Users" table does not match this migration. Missing or wrong: %', problems;
  end if;
end;
$$;

-- One GDG ID per Member. Members without one keep NULL, which never collides.
-- Added here, not in "create table", so it also reaches an existing table.
-- The old sign-up page saved a blank GDG ID as '', so clear those first.
update public."Users" set gdg_id = null where btrim(gdg_id) = '';
alter table public."Users" add constraint users_gdg_id_unique unique (gdg_id);

alter table public."Users" enable row level security;

-- ---------------------------------------------------------------------------
-- private.is_admin(): true when the signed-in Member is an Administrator.
-- security definer, so it can read Users whatever the caller's RLS allows.
-- An empty search_path stops a caller from shadowing the objects it uses.
-- ---------------------------------------------------------------------------
create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select u.is_admin from public."Users" u where u.user_id = (select auth.uid())),
    false
  );
$$;

revoke all on function private.is_admin() from public;
-- anon too: visitor policies like "is_public(...) or is_admin()" fail without it.
grant execute on function private.is_admin() to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Users policies (fixes finding F1 together with the guard trigger below).
-- A Member reads and edits only their own row; Administrators read and edit all
-- rows, which is how /admin grants and revokes the role. Nobody inserts from
-- the website: the sign-up trigger below creates each row.
--
-- Start from no policies at all, so whatever the live table had before can't
-- widen access. On a fresh database this loop finds nothing.
-- ---------------------------------------------------------------------------
do $$
declare
  existing record;
begin
  for existing in
    select policyname from pg_policies where schemaname = 'public' and tablename = 'Users'
  loop
    execute format('drop policy %I on public."Users"', existing.policyname);
  end loop;
end;
$$;

create policy "Members read their own row; Administrators read all"
  on public."Users" for select
  to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

create policy "Members edit their own row; Administrators edit all"
  on public."Users" for update
  to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()))
  with check (user_id = (select auth.uid()) or (select private.is_admin()));

-- Start from nothing: Supabase's default privileges include TRUNCATE, which
-- skips RLS. Visitors get no access; Members get only what the policies allow.
-- email is a copy of auth.users.email made at sign-up, so no Member edits it.
-- is_admin stays in the grant so Administrators can change it from /admin;
-- the guard trigger below stops everyone else.
revoke all on public."Users" from anon, authenticated;
grant select on public."Users" to authenticated;
grant update (first_name, last_name, gdg_id, campus, is_admin) on public."Users" to authenticated;

-- ---------------------------------------------------------------------------
-- Guard the Administrator flag.
-- RLS can't restrict a single column, so a trigger refuses any request from
-- the website (roles anon and authenticated) that sets or changes is_admin
-- unless the caller is already an Administrator. The project owner creates the
-- first Administrator from the SQL editor, where no website role applies.
--
-- Every other current_user skips the check: the SQL editor (postgres), the
-- service role, and any security definer function owned by postgres, because
-- current_user inside one is its owner. So a security definer function that
-- sets is_admin bypasses this guard: never write one the website can call.
-- private.create_user_row() below is security definer and never sets it.
-- ---------------------------------------------------------------------------
create or replace function private.guard_admin_flag()
returns trigger
language plpgsql
-- security invoker, so current_user is the real database role of the request
-- (anon/authenticated from the website, postgres from the SQL editor) and not
-- a JWT claim.
security invoker
set search_path = ''
as $$
begin
  if current_user not in ('anon', 'authenticated') then
    return new;
  end if;

  if tg_op = 'INSERT' and new.is_admin then
    raise exception 'Only an Administrator can grant the Administrator role'
      using errcode = '42501';
  end if;

  if tg_op = 'UPDATE'
     and new.is_admin is distinct from old.is_admin
     and not private.is_admin() then
    raise exception 'Only an Administrator can grant or revoke the Administrator role'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

revoke all on function private.guard_admin_flag() from public;

drop trigger if exists guard_admin_flag on public."Users";
create trigger guard_admin_flag
  before insert or update on public."Users"
  for each row execute function private.guard_admin_flag();

-- ---------------------------------------------------------------------------
-- Sign-up creates the Member's Users row.
-- The sign-up page passes the form fields to auth.signUp() as user metadata,
-- and this trigger copies them when Supabase Auth creates the auth.users row.
-- It runs inside Auth's insert, so it works with email confirmation on, when
-- the browser has no session yet.
--
-- Missing metadata (a user created from the dashboard) still makes a row, so
-- that account works and can be made an Administrator. Missing names and email
-- become '' because those columns are NOT NULL; the Member can fill in the
-- names later. Blank optional fields become NULL, so an empty GDG ID never
-- collides with another under users_gdg_id_unique. A GDG ID already in use
-- fails the whole sign-up, so no account is left without a row.
-- ---------------------------------------------------------------------------
create or replace function private.create_user_row()
returns trigger
language plpgsql
-- security definer: Auth inserts as supabase_auth_admin, which has no
-- privileges on public."Users". It never sets is_admin (see the guard above).
security definer
set search_path = ''
as $$
begin
  insert into public."Users" (user_id, first_name, last_name, gdg_id, email, campus)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name', ''),
    nullif(btrim(new.raw_user_meta_data ->> 'gdg_id'), ''),
    coalesce(new.email, ''),
    nullif(btrim(new.raw_user_meta_data ->> 'campus'), '')
  );
  return new;
end;
$$;

revoke all on function private.create_user_row() from public;

drop trigger if exists create_user_row on auth.users;
create trigger create_user_row
  after insert on auth.users
  for each row execute function private.create_user_row();
