# Database (Supabase)

Every change to the database is a migration in `migrations/`, so the database can be rebuilt and every change reviewed. The whole site uses one Supabase project ([ADR 0003](../../docs/adr/0003-one-supabase-project.md)), and the foundation owns the objects every feature shares ([ADR 0008](../../docs/adr/0008-foundation-owns-shared-database-objects.md)). Content is edited through `/admin` ([ADR 0001](../../docs/adr/0001-supabase-as-cms.md)).

## Run it locally

Needs Docker (Docker Desktop on Mac/Windows, Docker Engine on Linux) running. From `gdgoc/`:

```bash
npx supabase start               # local Postgres, Auth, Storage and API; applies migrations and seed.sql
npx supabase db reset            # rebuild from scratch after editing a migration
npx supabase test db             # pgTAP tests in tests/database/
npx supabase db advisors --local # security and performance advisors; must report nothing
npx supabase stop
```

Run `db reset`, `test db` and `db advisors` before every PR that touches this folder.

`supabase start` prints a local API URL and keys. They're public demo values, so you can put them in `.env.local` to point the app at your local database.

If another local Supabase project already uses ports 54320–54329, stop it first (`npx supabase stop --project-id <name>`).

## The foundation

These two migrations come before any feature. Feature migrations use what they create and never redefine it.

| Migration | Adds |
| --- | --- |
| `…_foundation.sql` | `private` schema, the shared `set_updated_at()` trigger, `private.is_public()` (which Publish status is public) |
| `…_administrators.sql` | `Users` baseline and RLS, the sign-up trigger that creates each Member's `Users` row, `private.is_admin()`, a trigger so only Administrators can change `is_admin` |

When you write a feature migration:

- **Point at Members with `public."Users"(user_id)`.** It equals `auth.users.id` (`auth.uid()`). There is no `profiles` table.
- **Check Administrators with `private.is_admin()`.** Don't add a feature's own admin list.
- **Use `private.set_updated_at()`** for `updated_at` columns. Don't create your own copy.
- **Don't create the `private` schema.** The foundation already does.
- **Something several features share** (for example notifications) goes in its own foundation migration, not inside one feature.

## Before applying to production

The migrations have only run on local databases so far. Check these in the dashboard first. The project is being recreated under an organisation account (PRD §5.5), and a fresh project avoids most of them.

- **`Users` columns:** the table already exists in production. `…_administrators.sql` stops with an error if it lacks a column the app uses or `is_admin` isn't a boolean. It also clears blank GDG IDs to NULL and adds a unique constraint on `gdg_id`, which fails if two rows share a real one; clean those up first.
- **`Users` policies:** the migration drops every live policy on `Users` before creating its own, so an older broad policy can't widen access. Unless this is the fresh project from PRD §5.5, dump them first and keep the output:

  ```sql
  select policyname, cmd, roles, qual, with_check
  from pg_policies where schemaname = 'public' and tablename = 'Users';
  ```

- **Email confirmation:** leave it on (hosted projects start with it on). Sign-up doesn't need a session: a trigger on `auth.users` creates the `Users` row from the sign-up form. Users created from the dashboard get a row too, with blank names. If the live project already has a trigger on `auth.users` that creates `Users` rows, drop it, or every sign-up fails on the duplicate row.

## Make the first Administrator

Members can't grant themselves the role. The project owner runs this once in the Supabase SQL editor, using the Member's sign-up email:

```sql
update public."Users" set is_admin = true
where user_id = (select id from auth.users where email = '<member email>');
```

Match on `auth.users`, which holds the Member's current sign-in email. `Users.email` is the copy made at sign-up: Members can't edit it, but it doesn't follow a later email change.

After that, Administrators grant and revoke the role from `/admin`.
