# Sprint 1 PRD: Engineering Response and Recommended Actions

**For:** Head of Product, Team Lead
**About:** [GDG Web - 1st Sprint PRD](GDG%20Web%20-%201st%20Sprint%20PRD.md)
**Date:** 2026-11-20
**Status:** decisions below are agreed by engineering; items marked **Open** need an answer from the Head of Product.

## Summary

Engineering cross-checked the Sprint 1 PRD against everything already written for the website: the signed Website Plan, the open proposal on GitHub (PR #6, `docs/proposals/0001`), its decision records (ADRs), the current site code, and the first database work for Events.

The headline:

- **The PRD now defines what gets built.** The earlier proposal stays only for *how* it's built: Supabase as the content system, database security rules, tested migrations.
- **The PRD and the security plan point the same way.** PRD §5.3 asks to validate inputs on the backend and restrict admin actions to authorised accounts. The current site does neither (every admin action runs in the browser), so the security work in the proposal is how we meet §5.3.
- **Four features share two patterns**, which keeps Sprint 1 smaller than it looks:
  - **Admin-published content:** Events and Announcements (draft, publish, unpublish, archive).
  - **Member submissions:** the Freedom Wall (pending, approved, rejected, moderation log, notifications).
- **One blocker stops any release:** the production Supabase project doesn't exist any more (see Blockers).

## 1. Decisions

### 1.1 Events (PRD §1)

All of the PRD's Events requirements are accepted. Engineering adds one change to how status works.

**Status is split into three parts.** The PRD's single status (Upcoming, Registration Open, Registration Closed, Ongoing) mixes three different things. Storing them separately means admins never have to move an event by hand when the date passes, and an event can't show the wrong status.

| Part | Who sets it | Values |
| --- | --- | --- |
| **Publish status** | Admin | Draft, Published, Unpublished, Archived |
| **Timing** | Automatic, from the start and end time | Upcoming, Ongoing, Completed |
| **Registration** | Admin, with an optional closing date that closes it automatically | Not open yet, Open, Closed |

What visitors see:

- **Coming Soon** lists Upcoming and Ongoing events, nearest first.
- **Previous Events** lists Completed events, newest first.
- The status label on an event card follows the PRD exactly:
  - Ongoing, if the event has started;
  - otherwise Upcoming, Registration Open or Registration Closed, from the registration setting.
- The Register button opens the registration link in a new tab. It's disabled when registration is closed or the event is over.

This also fixes a bug in the first draft, which moved an event into Previous Events the moment it started, even while still ongoing.

**Added to the schema:**

- **Time** as well as date (start and end).
- **Timeline:** an ordered list of schedule items per event (time, title, description).
- **Photo gallery:** photos linked to each event, in order, with a caption and alt text.
- **Archive:** archived events leave the public lists but stay in the admin panel.
- **Detail view:** each event gets its own page.
- **Search** by title and **filter** by year and category.

**Images:**

- Cover and gallery photos of a draft or unpublished event stay **private** until it's published.
- Uploads are images only, 2 MB at most, shrunk in the browser before upload.
- Each event's gallery has a cap, to protect the free storage quota (see Blockers).

**Dropped:** Previous Events Quotes (Website Plan item 10) aren't in Sprint 1, so their table is removed from this sprint's database work.

**Open:** the featured event and the category list (questions 1 and 2).

### 1.2 Freedom Wall (PRD §2)

- **Plain text only, up to 2,000 characters.** No Markdown, HTML, rich text, images, GIFs, background colors or stickers. The database enforces the limit as well as the form.
- **Topic is required**, from the PRD's six labels: General, Project/Collaboration, Tech Tips, Hackathon, Shoutout, Questions.
- **Anonymous posting:** the public never sees an anonymous author. Admins can, as PRD §2.6 requires.
- **Statuses:** Pending, Approved, Rejected (PRD §2.5).
- **Admins can edit** an approved post. It keeps its original author.
- **Admins can delete** a post. It disappears from the public feed at once, but the record behind it is kept so the moderation log stays complete.
- **Moderation log (new table).** Every approve, reject, edit and delete is recorded with:
  - the admin's account;
  - the date and time;
  - the rejection reason, where there is one;
  - for an edit, the text before and after.

  Only admins can read the log. Nobody can change or delete an entry, not even an admin.
- **Reactions:** Love, Ship It, Lit, Relatable and Tech. Each Member can give each reaction once per post. The feed can sort by popularity (total reactions).
- **In-app notifications** when a submission is approved or rejected: title, message, date and time, read or unread, and a link to the submission. They're created automatically when the status changes, so none can be missed.
- **Search** by keyword and **filter** by topic.

**Changes to the signed Website Plan:** Plan item 6 (colors, GIFs and pictures on wall posts) and item 7 (stickers) are **not in Sprint 1**. The Plan itself stays unchanged as a signed record, and this document records the change.

**Open:** how long rejected posts are kept. A separate proposal on this is coming from engineering.

### 1.3 Announcement Board (PRD §3)

This is new; it wasn't in the Website Plan or the earlier proposal. It's accepted as written in the PRD and reuses the Events pattern:

- **Statuses:** Draft, Published, Unpublished, Archived.
- **Pinned** announcements show in a featured section at the top.
- **Markdown** content, with a live preview in the editor. It's **sanitised** before display so no script can run.
- **Attachments:** images and PDFs, with a size limit per file.
- **Details:** the author is the publishing admin. The post date is set automatically, and "last updated" shows when a post has been edited.

### 1.4 Officers and Members (PRD §4)

- **Visitors** can view officer profiles.
- **Signed-in Members** can browse **all** members.
- **What a profile shows** (PRD §4.2): name, photo, role or position, department, social and professional links, and bio.
- **Never shown in the directory:** the **GDG ID**. Email and campus aren't shown either, because the PRD doesn't list them as profile fields.
- **Members** edit their own bio and links. **Admins** assign roles, committee placements and member statuses.
- **How it's protected:** the directory reads through a database view that contains only the profile fields above. Database security rules work on whole rows, not columns, so a view is the reliable way to make sure the GDG ID can never be read, whatever the page code does.

The member data belongs to real students. Since every Member is listed, we recommend a short notice at sign-up saying the profile fields are visible to other signed-in Members.

### 1.5 Wording and general requirements (PRD §5)

- **"Administrator"** (Admin) replaces "Moderator" everywhere: docs, glossary and database names, to match the PRD.
- **Access control** follows the PRD §5.1 table, and the database itself enforces it, not only the buttons on screen.
- **Times** are stored with their time zone and shown in Philippine Standard Time (PHT).
- **Input validation** happens on the server and in the database, as well as in the form.

## 2. Open questions for the Head of Product

| # | Question | Engineering recommendation |
| --- | --- | --- |
| 1 | Should the Events page have a **featured event** headlining it? The PRD doesn't mention one; the earlier design mockup does. | Keep at most one optional featured event. It's cheap, and easy to leave unused. |
| 2 | What are the **event categories** for the category filter? | Workshop, Hackathon, Sprint, Talk, Social, unless you want a different list. |
| 3 | What is the **priority order** of the four features within Sprint 1? | Events, Announcements, Freedom Wall, then Officers and Members (see section 4). |
| 4 | Can a Member **delete their own** Freedom Wall submission? The PRD doesn't say. | Yes, at any time. |
| 5 | Should there be a **limit on pending posts** per Member, as a spam guard? | Yes: at most 3 pending at a time. |
| 6 | Who **owns the Supabase project**, and should it be restored or recreated? | Recreate it under an organisation account the officers can hand over each year. |
| — | How long are **rejected posts** kept? | A separate proposal is coming. |

## 3. Blockers and risks

1. **No production database.** The Supabase project the site points to no longer exists; its address still didn't resolve when checked on 2026-11-20. Local development works, but nothing can be released until the project is restored or recreated.
2. **Security gaps in the current site** (findings F1–F3 in PR #6):
   - any Member can make themselves an admin;
   - every admin action runs from the browser;
   - the admin area has no check on the server.

   PRD §5.3 requires all three to be fixed. The database part of F1 is already done on the `feat/events-db` branch.
3. **Free plan storage:** 1 GB of files and 5 GB of downloads per month, shared across the project. Event galleries and announcement PDFs fill it first. We mitigate this by shrinking images before upload, capping gallery size and limiting file sizes.
4. **Sprint size.** The Website Plan schedules the Freedom Wall for weeks 3–4. The PRD puts four features into Sprint 1, so a priority order (question 3) lets us ship the most important feature first.

## 4. Recommended order of work

1. **Foundation** (everything depends on it):
   - recreate or restore the Supabase project;
   - connect the login session check;
   - check admin rights on the server;
   - tighten database permissions;
   - run the database security tests automatically on every pull request.
2. **Events:** rewrite the Events database work to match section 1.1, then build the page, the detail view and the admin screens.
3. **Announcements:** reuse the Events publishing pattern; add Markdown and attachments.
4. **Freedom Wall:** submissions, moderation queue, moderation log, reactions and notifications.
5. **Officers and Members:** profiles and the member directory.

## 5. What PR #6 on GitHub should update

PR #6 (`docs: agent workflow + Freedom Wall/Events proposal (RFC)`) is still a draft on the canonical repo, written before the PRD arrived. To reflect this document it should change as follows. It changes no app code, so all of this is documentation.

| File | Change |
| --- | --- |
| `resource/documentation/PRD/` | **Add** the Sprint 1 PRD and this response. |
| `docs/proposals/0001-freedom-wall-and-events.md` | Mark it **superseded in part** by the Sprint 1 PRD, linking here.<br>**Remove:** stickers, wall images, colors and the image bucket; 500-character posts; Event Quotes; "Upcoming/Past from start time only".<br>**Add:** the three-part event status, timeline, gallery, archive, reactions, notifications, moderation log, Announcement Board and member directory.<br>Rename Moderator to Administrator. |
| `GLOSSARY.md` | **Rename** Moderator to **Administrator**.<br>**Redefine** Wall Post (plain text, topic) and Review status (Pending, Approved, Rejected).<br>Replace Upcoming/Past with **Upcoming / Ongoing / Completed**.<br>**Add** Publish status, Registration status, Timeline, Gallery, Topic, Reaction, Notification, Moderation log, Announcement, Pinned announcement and Member directory.<br>**Remove** Sticker and Event Quote for now. |
| `docs/adr/0001-supabase-as-cms.md` | Rename `is_moderator()` to `is_admin()`. Add Announcements to the content the CMS manages. |
| `docs/adr/0002-anonymous-submissions-store-author.md` | Keep the decision. Drop Event Quotes from its scope for now. |
| `docs/adr/0003-one-supabase-project.md` | Keep the decision. Update the feature list. |
| **New ADRs** | **0004:** Event status is split into publish status, timing and registration.<br>**0005:** Freedom Wall posts are plain text only, 2,000 characters.<br>**0006:** The member directory reads through a view that never includes the GDG ID.<br>**0007:** The moderation log is append-only. |
| `AGENTS.md`, `docs/agents/workflow.md` | Replace "There is no test suite yet" with the database tests (`npx supabase test db`). Add them to the verify step. Point to `CODING_STANDARDS.md` and `gdgoc/supabase/`. |
| `resource/documentation/GDGoC Website Plan.md` | No change: it's the signed record. Section 1.2 above records which Plan items moved out of Sprint 1. |
| **PR description** | Update the summary and the architecture diagram (new tables, no wall image bucket).<br>Add this document's open questions to the review checklist.<br>Add two new findings: **F9**, draft event images are publicly reachable; **F10**, ongoing events show under Previous Events. Both are fixed in the plan above. |

The database work (`feat/events-db`, currently only on a fork) goes up as a **separate PR** after PR #6, so the decisions are reviewed before the code.

## Appendix: database plan (for developers)

All tables live in one Supabase project, created by migrations under `gdgoc/supabase/migrations/`, with Row Level Security (RLS) on every table and pgTAP tests for every rule.

| Table / view | Purpose | Key points |
| --- | --- | --- |
| `Users` (existing) | Accounts; `is_admin` is the Administrator flag | A trigger blocks non-admins from changing `is_admin` (F1). Table permissions revoked and re-granted narrowly. |
| `private.is_admin()` | Admin check used by every policy | Renamed from `is_moderator()`. |
| `events` | Events | `publish_status` (draft/published/unpublished/archived), `starts_at`/`ends_at`, `registration_status` (not_open/open/closed) plus `registration_closes_at`, `category`, `venue`, `registration_url`, `cover_path`; timing derived from `coalesce(ends_at, starts_at)`; indexes for year, category and title search. |
| `event_timeline_items` | Schedule per event | `event_id`, `starts_at`, `ends_at`, `title`, `description`, `position`. |
| `event_photos` | Gallery per event | `event_id`, `path`, `caption`, `alt_text`, `position`; capped per event. |
| `event-media` bucket | Covers and gallery | Private; readable by everyone only when the linked event is published; admins write. |
| `announcements` | Announcement Board | `publish_status`, `is_pinned`, Markdown `body` (sanitised on render), `category`, `author_id`, `published_at`, `updated_at`. |
| `announcement_attachments` + bucket | Images and PDFs | Size and type limits per file. |
| `wall_posts` | Freedom Wall | `author_id`, `body` (1–2,000 chars, plain text), `topic` (6 labels), `is_anonymous`, `status` (pending/approved/rejected), `deleted_at`. |
| `public_wall_posts` (view) | Public feed | Approved and not deleted only; author blanked when anonymous (ADR-0002). |
| `wall_reactions` | Reactions | Unique per (post, member, reaction type); five types. |
| `moderation_log` | Audit trail | `admin_id`, `action` (approve/reject/edit/delete), `target`, `reason`, `before`/`after`, `created_at`; insert-only, admins read. |
| `notifications` | In-app notifications | `user_id`, `title`, `message`, `link`, `read_at`, `created_at`; created by a trigger on status change. |
| `member_directory` (view) | Member directory | Name, photo, role, department, links and bio only. No GDG ID, email or campus. |
