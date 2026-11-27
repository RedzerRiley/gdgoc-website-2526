---
status: accepted
---

# The foundation owns the database objects every feature shares

One set of migrations, the foundation, owns what more than one feature depends on: the Member table, the Administrator role and the shared helpers. Feature migrations (Events, the Freedom Wall, Announcements) use these objects and never create or redefine them.

| Owned by the foundation | Owned by each feature |
| --- | --- |
| `public."Users"`: one row per Member, keyed by `user_id` = `auth.users.id` | Its own tables, named with the feature's prefix (`events`, `event_*`, `freedom_wall_*`) |
| The Administrator role: `Users.is_admin`, the check `private.is_admin()` and the trigger that guards the flag | Its own RLS policies, which call `private.is_admin()` |
| The `private` schema and shared helpers such as `private.set_updated_at()` | Its own migration files and pgTAP tests |
| `supabase/config.toml` (one config file for the project) | How the website reaches it: tables with RLS, or functions only |

Any table that points at a Member references `public."Users"(user_id)`. A feature that needs a new shared object (for example a `notifications` table that several features write to) adds it to the foundation in its own migration instead of creating it inside the feature.

## Why

Events and the Freedom Wall were built in parallel on separate branches. With nobody owning the shared objects, each branch made its own:

- The Freedom Wall referenced a `profiles` table that no migration creates and the app never reads, so its migration failed on a fresh database.
- It kept its own Administrator list (`freedom_wall_admins`), so an Administrator for Events would not have been one for the Freedom Wall, and `/admin` would have needed two ways to grant the role.
- Both branches created `private.set_updated_at()` with `create or replace`, so whichever ran last silently replaced the other.

Separate Supabase projects would not fix this ([ADR 0003](0003-one-supabase-project.md)). They would copy the Member table and the Administrator list instead of sharing them.

## Consequences

- The foundation merges first. Every feature PR is based on it.
- Changing a foundation object is a foundation change: its own PR, with its tests in `administrators.test.sql` or a new foundation test file.
- One Administrator flag means one place to grant and revoke the role, and one check (`private.is_admin()`) to test.
