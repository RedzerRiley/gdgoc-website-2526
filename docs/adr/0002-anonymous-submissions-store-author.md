---
status: proposed
---

# Anonymous Submissions still store their author

An Anonymous Wall Post still records `author_id`. Only the public display hides it: the public reads the `public_wall_posts` view, which returns approved rows only and blanks out the author when `is_anonymous` is true. The base table can be read only by the author and Administrators.

We chose this over truly anonymous (authorless) storage because the Sprint 1 PRD (§2.6) requires that "Administrators must still be able to identify anonymous submitters", so they can act on harassment and spam, and so authors can see and delete their own Submissions. The promise to Members is "other members never see who you are", not "nobody can know", and the submit form says so plainly.

The same rule applies to any future Submission type.

## Consequences

Row Level Security hides whole rows, not single columns. So no policy may ever give the public a `select` on the base table, or the author would leak. Public reads must go through the view.
