-- The Administrator role (Users.is_admin): who can grant and revoke it, and
-- that losing it makes private.is_admin() false straight away. Every feature's
-- RLS policies call private.is_admin(), so that one check covers them all.
-- Also how sign-up creates the Users row, and what a Member can't write there.

begin;
create extension if not exists pgtap with schema extensions;

select plan(19);

-- Signing up inserts into auth.users with the form as metadata; the trigger
-- creates each Users row.
insert into auth.users (id, email, aud, role, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 'admin@example.com',  'authenticated', 'authenticated',
   '{"first_name": "Jane", "last_name": "Doe", "gdg_id": "25001", "campus": "intramuros"}'),
  ('00000000-0000-0000-0000-00000000000b', 'member@example.com', 'authenticated', 'authenticated',
   '{"first_name": "John", "last_name": "Doe", "gdg_id": "25002", "campus": "makati"}'),
  ('00000000-0000-0000-0000-00000000000c', 'other@example.com',  'authenticated', 'authenticated',
   '{"first_name": "Jim", "last_name": "Doe", "gdg_id": "25003", "is_admin": true}'),
  ('00000000-0000-0000-0000-00000000000d', 'admin2@example.com', 'authenticated', 'authenticated',
   '{"first_name": "June", "last_name": "Doe", "gdg_id": "25004"}');

-- The project owner makes the first Administrators, as in the README.
update public."Users" set is_admin = true
where user_id in ('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000d');

create function pg_temp.act_as(p_user uuid) returns void language sql as $$
  select set_config('role', 'authenticated', true),
         set_config('request.jwt.claims',
                    json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
$$;

-- ---------------------------------------------------------------------------
-- Visitors have no access to Users at all
-- ---------------------------------------------------------------------------
select ok(not has_table_privilege('anon', 'public."Users"', 'select'),
          'a visitor has no select privilege on Users');
select ok(not has_table_privilege('authenticated', 'public."Users"', 'delete'),
          'a Member has no delete privilege on Users');
-- TRUNCATE skips RLS, so no website role may hold it on any table here.
select is(
  (select array_agg(distinct c.relname::text order by c.relname::text)
   from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   cross join unnest(array['anon', 'authenticated']) r(role)
   where n.nspname = 'public' and c.relkind in ('r', 'v')
     and (has_table_privilege(r.role, c.oid, 'truncate')
          or has_table_privilege(r.role, c.oid, 'trigger')
          or has_table_privilege(r.role, c.oid, 'references'))),
  null,
  'website roles hold no truncate, trigger or references privilege on public tables');

-- ---------------------------------------------------------------------------
-- Signing up
-- ---------------------------------------------------------------------------
select results_eq(
  $$ select first_name, last_name, gdg_id, email, campus, is_admin
     from public."Users" where user_id = '00000000-0000-0000-0000-00000000000b' $$,
  $$ values ('John', 'Doe', '25002', 'member@example.com', 'makati', false) $$,
  'signing up creates the Users row from the sign-up form');

select is((select is_admin from public."Users" where user_id = '00000000-0000-0000-0000-00000000000c'), false,
          'signing up with is_admin in the form data does not make an Administrator');

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000000e', 'dashboard@example.com', 'authenticated', 'authenticated');
select results_eq(
  $$ select first_name, last_name, gdg_id, email, campus
     from public."Users" where user_id = '00000000-0000-0000-0000-00000000000e' $$,
  $$ values ('', '', null::text, 'dashboard@example.com', null::text) $$,
  'a user created without sign-up metadata still gets a Users row');

insert into auth.users (id, email, aud, role, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000f', 'blank@example.com', 'authenticated', 'authenticated',
   '{"first_name": "Jill", "last_name": "Doe", "gdg_id": ""}'),
  ('00000000-0000-0000-0000-000000000019', 'blank2@example.com', 'authenticated', 'authenticated',
   '{"first_name": "Jack", "last_name": "Doe", "gdg_id": "  "}');
select is((select count(*)::int from public."Users"
           where user_id in ('00000000-0000-0000-0000-00000000000f', '00000000-0000-0000-0000-000000000019')
             and gdg_id is null), 2,
          'a blank GDG ID is stored as NULL, so two blank ones do not collide');

select throws_ok(
  $$ insert into auth.users (id, email, aud, role, raw_user_meta_data) values
     ('00000000-0000-0000-0000-000000000010', 'copycat@example.com', 'authenticated', 'authenticated',
      '{"first_name": "Jack", "last_name": "Doe", "gdg_id": "25002"}') $$,
  '23505', null, 'signing up with a GDG ID already in use is refused');

-- ---------------------------------------------------------------------------
-- Granting
-- ---------------------------------------------------------------------------
select pg_temp.act_as('00000000-0000-0000-0000-00000000000c');
select throws_ok(
  $$ insert into public."Users" (user_id, first_name, last_name, email)
     values ('00000000-0000-0000-0000-00000000000c', 'Jim', 'Doe', 'other@example.com') $$,
  '42501', null, 'a Member cannot insert a Users row directly');

select pg_temp.act_as('00000000-0000-0000-0000-00000000000b');
select throws_ok(
  $$ update public."Users" set is_admin = true where user_id = '00000000-0000-0000-0000-00000000000b' $$,
  '42501', null, 'a Member cannot make themselves an Administrator');

select is((select count(*)::int from public."Users"), 1, 'a Member reads only their own Users row');

select lives_ok(
  $$ update public."Users" set first_name = 'Johnny' where user_id = '00000000-0000-0000-0000-00000000000b' $$,
  'a Member can still edit their own profile');

select throws_ok(
  $$ update public."Users" set email = 'someone-else@example.com' where user_id = '00000000-0000-0000-0000-00000000000b' $$,
  '42501', null, 'a Member cannot change the email on their Users row');

select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');
select lives_ok(
  $$ update public."Users" set is_admin = true where user_id = '00000000-0000-0000-0000-00000000000b' $$,
  'an Administrator can grant the Administrator role');

-- ---------------------------------------------------------------------------
-- Revoking
-- ---------------------------------------------------------------------------
select is((select count(*)::int from public."Users"), 7,
          'an Administrator reads every Users row (setup check for the next tests)');

select lives_ok(
  $$ update public."Users" set is_admin = false where user_id = '00000000-0000-0000-0000-00000000000d' $$,
  'an Administrator can revoke another Administrator');

select pg_temp.act_as('00000000-0000-0000-0000-00000000000d');
select is((select private.is_admin()), false,
          'a revoked Administrator is no longer an Administrator');
select throws_ok(
  $$ update public."Users" set is_admin = true where user_id = '00000000-0000-0000-0000-00000000000d' $$,
  '42501', null, 'a revoked Administrator cannot grant the role back to themselves');

-- RLS hides other Members' rows, so this update matches nothing.
select pg_temp.act_as('00000000-0000-0000-0000-00000000000c');
update public."Users" set is_admin = false where user_id = '00000000-0000-0000-0000-00000000000a';
reset role;
select is((select is_admin from public."Users" where user_id = '00000000-0000-0000-0000-00000000000a'), true,
          'a Member cannot revoke an Administrator');

select * from finish();
rollback;
