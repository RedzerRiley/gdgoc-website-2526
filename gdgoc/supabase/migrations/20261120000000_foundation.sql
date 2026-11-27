-- Foundation: shared setup that later feature migrations build on.
-- Nothing here belongs to one feature; feature rules live in their own files.

-- ---------------------------------------------------------------------------
-- private schema: helpers the website's API never exposes.
-- It is not in [api].schemas in config.toml, so PostgREST can't reach it.
-- RLS policies run as the calling role, so that role needs USAGE to call
-- the helpers from inside a policy.
-- ---------------------------------------------------------------------------
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Shared trigger: keep updated_at current on every table that has one.
-- ---------------------------------------------------------------------------
create or replace function private.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function private.set_updated_at() from public;

-- ---------------------------------------------------------------------------
-- private.is_public(): which Publish status the public may see (GLOSSARY.md).
-- Events use it now; Announcements reuse the same Publish status later.
-- Policies, constraints and triggers call this instead of repeating the
-- literal. Partial indexes can't: the planner only uses them when a query
-- repeats their exact predicate, so they keep publish_status = 'published'.
-- ---------------------------------------------------------------------------
create or replace function private.is_public(p_publish_status text)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $$
  select p_publish_status = 'published';
$$;

revoke all on function private.is_public(text) from public;
grant execute on function private.is_public(text) to anon, authenticated, service_role;
