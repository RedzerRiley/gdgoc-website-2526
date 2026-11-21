---
status: proposed
---

# One Supabase project for the whole site

Events, the Freedom Wall, Announcements, the Officers and Members page and the existing Officers and Products content all live in a single Supabase project, not separate databases. Per the Sprint 1 PRD (§5.5), it is recreated under an organisation-owned account that can be handed over to the officers each year.

- **Code:** tables in `public` are grouped by feature into migration files under `supabase/migrations/`.
- **Internals:** helpers such as `is_admin()` and the cleanup jobs sit in a `private` schema that the website's API never exposes.

We rejected separate projects for four reasons:

- The Free Plan allows only **two active projects per person**.
- Storage, egress and monthly-user quotas are **per organisation**, so splitting adds no capacity.
- Auth is per project, so Members would need separate accounts.
- Tables in different projects can't reference each other, so the moderation log couldn't point at Wall Posts, and the review queue couldn't join Submissions with the Administrator flag.

Separation for organisation and security comes from per-feature migrations, Row Level Security and the `private` schema instead.

## Consequences

One free project means a single point of failure:

- A GitHub Action reads the database every few days so the project never pauses.
- A weekly export saves Events and CMS content. It never includes member data.
