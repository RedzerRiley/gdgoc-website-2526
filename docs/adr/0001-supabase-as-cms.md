---
status: proposed
---

# Supabase plus an in-site /admin is the CMS

Content such as Events and Announcements, and moderation of Submissions, is managed in Supabase tables through an `/admin` area inside the website, open to Administrators only. We chose this over a separate CMS (Sanity, Payload or Decap). The chapter's officers change every year, so the handoff has to be just "make the new officers Administrators", with no second system, login or bill to pass along. The site already edits Officers and Products this way, and the review queue needs an admin screen anyway.

## Considered options

- **Sanity:** a hosted editor, but a second set of accounts to hand over, and overkill for about 10 events a year.
- **Payload:** runs inside Next.js, but brings a heavy framework and its own admin and auth layer alongside Supabase Auth.
- **Decap (git-based):** content lives in the repo, but editors need GitHub access and every edit triggers a deploy.

## Consequences

Editing in the CMS is only as safe as the database's Row Level Security rules. Every table the CMS writes to must check `private.is_admin()` in its policies.
