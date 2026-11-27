---
status: proposed
---

# Anonymous Submissions still store their author

An Anonymous Wall Post still records `author_id`. Only the public display hides it. The public reads Wall Posts through the `list_freedom_wall_posts()` function, which returns approved posts only, shows `Anonymous` as the author when `is_anonymous` is true, and never returns `author_id` or `is_anonymous`. The website roles have no grant on the base table, so authors and Administrators read it only through their own functions (`get_my_freedom_wall_submissions()` and `admin_list_freedom_wall_submissions()`).

We chose this over truly anonymous (authorless) storage because the Sprint 1 PRD (§2.6) requires that "Administrators must still be able to identify anonymous submitters", so they can act on harassment and spam, and so authors can see and delete their own Submissions. The promise to Members is "other members never see who you are", not "nobody can know", and the submit form says so plainly.

The same rule applies to any future Submission type.

## Consequences

Row Level Security hides whole rows, not single columns. So the public must never get a `select` on the base table, or the author would leak. Public reads must go through `list_freedom_wall_posts()`.
