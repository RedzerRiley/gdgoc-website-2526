---
status: proposed
---

# Event status is stored in three parts

The Sprint 1 PRD gives each Event one status: Upcoming, Registration Open, Registration Closed or Ongoing. We store it as three separate things and build the PRD's label from them:

- **Publish status** (draft, published, unpublished, archived), set by an Administrator.
- **Event timing** (Upcoming, Ongoing, Completed), never stored: it follows from `starts_at` and `ends_at`.
- **Registration status** (not open yet, open, closed), set by an Administrator, with an optional `registration_closes_at` that closes it automatically.

The label shown is Ongoing once the Event has started; before that it's Upcoming, Registration Open or Registration Closed, from the registration status.

We chose this because the single status mixes facts that change for different reasons. A stored "Ongoing" would need someone to change it by hand at the right minute, and would be wrong whenever they forget. Splitting it also fixes an earlier draft that moved an Event into Previous Events the moment it started.

## Consequences

Coming Soon is "timing is Upcoming or Ongoing", Previous Events is "timing is Completed", computed with `coalesce(ends_at, starts_at)`. Admins never move Events between sections. Any query that lists Events must use the same rule, so it lives in one place (a view or a shared function), not in each page.
