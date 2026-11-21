---
status: proposed
---

# The member directory reads through a view without the GDG ID

Signed-in Members can browse all Members (Sprint 1 PRD §4.3). They read the directory through a `member_directory` view that contains only the profile fields in PRD §4.2: name, photo, role or position, department, social and professional links, and bio. The GDG ID is never in the view. Email and campus aren't either, because the PRD doesn't list them as profile fields.

We chose a view because Row Level Security works on whole rows, not columns. A policy letting Members read each other's `Users` rows would expose every column, including the GDG ID, to anyone who queries the table directly, whatever the page code shows.

## Consequences

- No policy gives Members `select` on other Members' rows in `Users`. They read their own row; Administrators read all rows.
- Adding a field to the directory is a deliberate change to the view, reviewed like any migration.
- The member data belongs to real students, so the sign-up form tells Members which profile fields other signed-in Members can see.
