# Coding standards

The rules the reviewer enforces (`/code-review` reads this file). A rule that a machine can check belongs in a lint rule, test or CI job instead; keep this file for judgement calls and for rules that aren't automated yet.

## Database (`gdgoc/supabase/`)

The app talks to Supabase with the public anon key, so Row Level Security (RLS) is the only real protection (see `AGENTS.md`).

### Migrations

- Every database change is a new file from `npx supabase migration new <name>`. Never edit a migration that has already been applied to production; add a new one.
- Group a migration by feature (events, wall, moderation), matching ADR-0003.
- A migration that touches a table that existed before this repo recorded the schema (`Users`, `Officers`, `Products`) must not destroy or rewrite production data. Use `if not exists` / `drop ... if exists` and say in a comment what it assumes about production.

### Security

- Every new table runs `enable row level security` in the same migration that creates it.
- Every write policy on CMS content checks `(select private.is_admin())` (ADR-0001). Hiding a button with `isAdmin` is not security.
- Wrap auth helpers in policies as `(select auth.uid())` and `(select private.is_admin())`, so Postgres evaluates them once per query instead of once per row.
- Give each policy a `to` role (`anon`, `authenticated`) and one command (`select`, `insert`, `update`, `delete`). Avoid `for all`.
- Grant table privileges explicitly (`grant select ... to anon, authenticated`). Grant only what a policy allows.
- No policy gives the public `select` on a Submission base table; public reads go through a view or a function that hides the author (ADR-0002).
- No policy lets a Member read other Members' `Users` rows; the directory goes through the `member_directory` view, which never includes the GDG ID (ADR-0006).
- RLS can't restrict single columns. Protect a privileged column (`is_admin`, `status`) with a trigger, and check the real role with `current_user`, not a JWT claim.

### Functions

- Helpers that the website must not call directly live in the `private` schema.
- Every function sets `set search_path = ''` and schema-qualifies every name.
- Use `security definer` only when the function must read past the caller's RLS, and say why in a comment. Prefer `security invoker`.
- After `create function`, `revoke all ... from public`, then grant `execute` only to the roles that need it.

### Data rules

- Put rules about valid data in the table as `check`, `not null`, `unique` or foreign-key constraints, not only in the app. Name each constraint (`<table>_<rule>`).
- Prefer a `text` column with a `check (... in (...))` over a Postgres `enum` for lists the chapter may change (categories, palettes).
- Never store what can be derived. For example, Upcoming or Past follows from `starts_at`.
- Use `timestamptz` for times and `uuid` primary keys from `gen_random_uuid()`.
- Index every foreign key, and every column an RLS policy or a common query filters on. Use partial indexes for filtered lists (`where is_published`).

### Storage

- Every bucket is created in a migration with `file_size_limit` and `allowed_mime_types`.
- Writes to a bucket are limited to the roles that may write, with policies on `storage.objects` scoped by `bucket_id`.
- A bucket that holds unapproved Submissions is private.

### Tests and data

- Every rule a Member must not be able to get around has a pgTAP test in `gdgoc/supabase/tests/database/`: who can read, who can write, and the privileged-column triggers.
- `seed.sql` and test fixtures use fake placeholders only (`Jane Doe`, `member@example.com`). Never real member data.
