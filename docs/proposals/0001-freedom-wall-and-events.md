# Proposal 0001: Events, Freedom Wall and the in-site CMS

**Status:** proposed, revised on 2026-11-21 to follow the Sprint 1 PRD (V.2). Once issues are turned on, this moves to a GitHub issue and gets split into tickets.
**Scope source:** [`resource/documentation/PRD/NEW/GDG Web - 1st Sprint PRD (V.2).md`](../../resource/documentation/PRD/NEW/GDG%20Web%20-%201st%20Sprint%20PRD%20(V.2).md) decides **what** gets built. This proposal decides **how**. Where they differ, the PRD wins.
**Covers:** PRD §1 (Events), §2 (Freedom Wall), §5 (general requirements) and the CMS foundation they share. Officers and Members (§4) and Announcements (§3) get their own designs; they reuse the patterns here.
**Vocabulary:** terms in **bold** are defined in [`GLOSSARY.md`](../../GLOSSARY.md).
**Decision records:** [ADR-0001](../adr/0001-supabase-as-cms.md) to [ADR-0007](../adr/0007-moderation-log-append-only.md).

## Sprint 1 order (PRD §5.4)

1. Events
2. Officers and Members
3. Freedom Wall
4. Announcements

## Problem Statement

- **Events are invisible to everyone else.** The Events page shows hardcoded events. An **Administrator** can "edit" them, but the edit is only saved in that browser's local storage, so nobody else sees it and it disappears when storage is cleared.
- **Content dies with the handoff.** No officer can maintain content across a yearly handoff without editing code.
- **The Freedom Wall doesn't exist yet.** Members have no moderated place to post community messages.
- **The data layer can't be rebuilt or trusted:**
  - The Supabase project the site uses no longer exists.
  - Its structure isn't recorded anywhere in the repo.
  - Members can grant themselves admin rights from the browser.

## Solution

**Foundation (shared by every feature):**

- A new Supabase project under an organisation-owned account (PRD §5.5), built entirely from committed migrations.
- An `/admin` area inside the site, checked on the server, where Administrators manage content and review Submissions.
- Every rule enforced by the database itself (PRD §5.3).

**Events (PRD §1):**

- An optional **Featured event**, then **Coming Soon** and **Previous Events**.
- Each Event has a category, cover image, description, date and time, venue, **Timeline**, registration link and, once completed, a **Gallery**.
- The status label comes from three stored parts (ADR-0004): **Publish status**, **Event timing** and **Registration status**.
- A detail page per Event, search by title, and filters by year and **Event category**.
- Administrators create, edit, delete, publish, unpublish and archive Events, and set or clear the Featured event.

**Freedom Wall (PRD §2):**

- Signed-in **Members** post plain-text **Wall Posts** (ADR-0005) with a **Topic**, optionally **Anonymous**.
- A post becomes public only after an Administrator approves it. Each Member may have one pending post at a time.
- Members see their own Submissions and **Review status**, can delete them at any time, and get a **Notification** when one is approved or rejected.
- Visitors read approved posts, filter by Topic, search by keyword, and sort by newest or by **Reactions**.
- Administrators approve, reject with a reason, edit and delete posts. Every action goes to the **Moderation log** (ADR-0007).

## User Stories

### Visitors and the Events page

1. As a visitor, I want to see the Featured event at the top when there is one, so that I notice the chapter's main event.
2. As a visitor, I want Coming Soon to list upcoming and ongoing Events, nearest first, so that the next thing to attend is easy to find.
3. As a visitor, I want each Event to show a status (Upcoming, Registration Open, Registration Closed or Ongoing), so that I know whether I can still register.
4. As a visitor, I want the Register button to open the registration link in a new tab, and to be disabled when registration is closed, so that I don't hit a dead form.
5. As a visitor, I want Previous Events listed newest first, with a Gallery, so that I can see what the chapter has done.
6. As a visitor, I want to filter Events by year and by category (Workshop, Hackathon, Talk, Social), so that I find the kind of event I like.
7. As a visitor, I want to search Events by title, so that I find a specific one quickly.
8. As a visitor, I want to open an Event's detail page with its Timeline, so that I know the schedule.

### Administrators and Events

9. As an Administrator, I want to create, edit and delete Events, so that the page stays current without code changes.
10. As an Administrator, I want to upload a cover image and Gallery photos, so that each Event looks complete.
11. As an Administrator, I want to add and edit an Event's Timeline, so that visitors see the schedule.
12. As an Administrator, I want to set registration as not open yet, open or closed, with an optional closing time, so that the Register button is always right.
13. As an Administrator, I want an Event to move from Coming Soon to Previous Events by itself when it ends, so that I never have to move it by hand.
14. As an Administrator, I want to save an Event as a draft, then publish, unpublish or archive it, so that nothing half-finished goes public.
15. As an Administrator, I want draft Events' images to stay private until publication, so that unreleased posters don't leak.
16. As an Administrator, I want to set or clear the Featured event, with at most one at a time, so that the page has one clear headline.

### Members and the Freedom Wall

17. As a visitor, I want to read approved Wall Posts without signing in, so that I can see what the community is sharing.
18. As a visitor, I want to filter Wall Posts by Topic, search by keyword and sort by newest or most Reactions, so that I find posts I care about.
19. As a Member, I want to write a plain-text Wall Post of up to 2,000 characters with a live counter, so that I know how much room I have.
20. As a Member, I want to pick a Topic, which is required, so that my post is filed in the right place.
21. As a Member, I want to post Anonymously, and to be told plainly that Administrators can still see who wrote it, so that I understand what "anonymous" means here.
22. As a Member, I want to be told I can have only one pending post at a time, so that the queue stays fair.
23. As a Member, I want a "My submissions" page with each post's Review status and any rejection reason, so that I know what happened to it.
24. As a Member, I want to delete my own Wall Post at any time, so that I stay in control of what I've shared.
25. As a Member, I want a Notification when my post is approved or rejected, with an unread counter in the navigation bar, so that I don't have to keep checking.
26. As a Member, I want to give each Reaction once per post, so that I can respond without writing a reply.

### Administrators and moderation

27. As an Administrator, I want one queue of pending posts showing the submitter's account, Topic and whether it's Anonymous, so that I can review fairly.
28. As an Administrator, I want to approve a post, or reject it with a reason, so that the author knows why.
29. As an Administrator, I want to edit or delete an approved post, keeping its original author, so that I can fix or take down something harmful.
30. As an Administrator, I want rejected posts kept for 30 days and then deleted automatically, so that other Administrators have time to review them.
31. As an Administrator, I want every moderation action recorded with my account, so that the team can see who did what.

### The chapter and future officers

32. As the Team Lead, I want every database change committed as a migration, so that the database can be rebuilt and every change reviewed.
33. As the Team Lead, I want the free project kept awake automatically, so that the site doesn't go down between semesters.
34. As the Team Lead, I want a weekly export of Events and CMS content (no member data), so that a lost project doesn't erase a year of events.
35. As an Administrator, I want to grant and revoke the Administrator role in `/admin`, and `/admin` to refuse everyone else on the server, so that the yearly handoff needs no database access and hiding a button isn't our only protection.

## Implementation Decisions

**Architecture** (ADR-0001, ADR-0003)

- One Supabase project, under an organisation-owned account.
- Public tables live in `public`, grouped into migration files by feature.
- Internal helpers live in a `private` schema that the website's API never exposes: `is_admin()`, the 30-day cleanup and the pending-limit check.
- Pages that read data are Server Components using a server Supabase client.
- Every write is a Server Action that runs as the signed-in user, so Row Level Security (RLS) always applies.
- A Next.js `proxy` refreshes the login session on every request. This connects the existing but unused auth middleware.
- `/admin` checks the Administrator flag on the server.

**Administrator flag**

- `Users.is_admin` is the Administrator flag. A trigger stops anyone but an Administrator from setting or changing it, including at sign-up.
- The first Administrator is created by the project owner with a one-time SQL command, which the setup guide documents.

**Events** (ADR-0004)

- **events:** `title`, `summary`, `body`, `category` (workshop, hackathon, talk, social), `starts_at`, `ends_at`, `venue`, `cover_path`, `registration_url`, `registration_status`, `registration_closes_at`, `publish_status`, `is_featured`, timestamps.
  - At most one Event is featured, and only a published one.
  - Event timing is computed from `coalesce(ends_at, starts_at)`, in one shared place, never stored.
- **event_timeline_items:** `event_id`, `starts_at`, `ends_at`, `title`, `description`, `position`.
- **event_photos:** `event_id`, `path`, `caption`, `alt_text`, `position`, capped per Event.
- The public sees only published Events; Administrators see and write everything.

**Moderation model** (Freedom Wall)

- **wall_posts:** `author_id`, `body` (1–2,000 characters, plain text), `topic`, `is_anonymous`, `status` (pending, approved, rejected), `rejection_reason`, `reviewed_by`, `reviewed_at`, timestamps.
- Only Administrators change `status`. Members can't set it on insert.
- A database rule limits each Member to one pending post.
- Rejected posts are deleted 30 days after rejection by a scheduled job.
- Members can delete their own posts at any time. Deleted posts leave the public feed at once.
- **moderation_log:** append-only, written by triggers (ADR-0007).
- **wall_reactions:** one row per (post, Member, reaction type), five types.
- **notifications:** `user_id`, `title`, `message`, `link`, `read_at`, created by a trigger when a post is approved or rejected.

**Anonymous** (ADR-0002)

- `author_id` is always stored.
- The public reads Wall Posts only through the `public_wall_posts` view, which returns approved rows and blanks out the author when `is_anonymous` is set.
- The base table can be read only by the author and Administrators.

**Storage** (Free Plan: 1 GB of files and 5 GB of downloads per month, shared across the organisation)

- `event-media` holds covers and Gallery photos. It is **private**: files are readable by everyone only once their Event is published, and only Administrators write.
- Uploads are images only, 2 MB at most, shrunk in the browser to WebP at about 1280 px wide.
- The Freedom Wall uses no storage (ADR-0005).

**Times**

- All times are `timestamptz` and shown in Philippine Standard Time (PHT).

**Operations:**

- Development runs on a local Supabase (`supabase start`) with migrations under `supabase/migrations/`.
- A scheduled GitHub Action reads the database every few days to keep the project awake.
- A weekly GitHub Action exports Events and CMS content as a private workflow artifact. Member data is never included.

## Testing Decisions

- Good tests check behaviour you can observe from outside, such as "a non-Administrator can't approve", not internal details.
- **Database security rules** are tested directly with pgTAP (`supabase test db`) against the local Supabase. These are the highest-stakes tests: the anonymous author never leaks, Members can't approve or make themselves Administrators, the pending limit holds, draft images stay private, and the moderation log can't be changed.
- **Feature behaviour** is tested with Vitest by calling Server Actions against the local Supabase.
- No UI tests in version 1. Checking the UI against the design is done by hand.

## Out of Scope

- **Officers and Members (PRD §4):** its own design. The member directory rule is already decided (ADR-0006).
- **Announcements (PRD §3):** its own design, last in priority. It reuses the Events publish status.
- **Not in Sprint 1:** Event Quotes (Website Plan item 10), images and stickers on Wall Posts (items 6 and 7), email notifications, and the "Propose an Event" form.
- **Unchanged for now:** Officers and Products keep their current inline editing until the Officers and Members design replaces it.

## Assumptions to verify (Team Lead)

1. The old Supabase project is gone, and the new one will be created under an organisation account (PRD §5.5). Its address still didn't resolve on 2026-11-21.
2. `is_admin` was only ever set by hand in the dashboard, and nobody depends on setting it any other way.
3. The current RLS policies on `Users`, `Officers` and `Products` are unknown, so they are redone as migrations.
4. The chapter stays on the Supabase **Free Plan**.
5. The team plan and PRDs in `resource/documentation/` (with names removed) are fine to publish in this public repo.

## Findings (existing bugs and risks)

| # | Finding | Evidence | Severity |
|---|---|---|---|
| F1 | Members can make themselves admin | Sign-up inserts `is_admin` from the browser using the public key. Only RLS, which isn't recorded anywhere, could stop a crafted request. | High |
| F2 | All admin writes rely on the browser | Edits to Officers, Products and their ordering run in the browser. `isAdmin` only hides the buttons. | High (depends on RLS) |
| F3 | Auth middleware is never connected | `utils/supabase/middleware.ts` isn't imported by any `middleware`/`proxy` entry, so `/admin` has no server-side guard. | Medium |
| F4 | Docker builds could include secrets | `.dockerignore` didn't exclude `.env*`, and the Dockerfile copies the whole folder. **Fixed in this PR.** | Medium |
| F5 | Event edits only save locally | The Events page keeps admin edits in each browser's local storage. | Medium |
| F6 | The Supabase project no longer exists | Its address doesn't resolve (checked 2026-11-20 and 2026-11-21), and the structure can't be rebuilt from the repo. | High (site data) |
| F7 | Two names for the Supabase key | The client and the middleware read different variables (`..._PUBLISHABLE_DEFAULT_KEY` and `..._ANON_KEY`). | Low |
| F8 | Real names were in the planning docs | Member and signatory names were in the team plan. **Removed in this PR.** | Low |
| F9 | Draft event images would be public | The first version of this proposal used a public `event-images` bucket, so an unpublished Event's poster was reachable by URL. **Fixed above:** `event-media` is private until publication. | Medium |
| F10 | Ongoing events would show as Previous | The first version split Upcoming and Past on `starts_at` alone. **Fixed above** (ADR-0004). | Medium |

Once issues are turned on, each open finding becomes a GitHub issue labelled `needs review`.
