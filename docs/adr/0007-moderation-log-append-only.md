---
status: proposed
---

# The moderation log is append-only

Every approve, reject, edit and delete of a Submission writes one row to `moderation_log`: the Administrator's account, the action, the time, the rejection reason if any, and for an edit the text before and after. This meets the Sprint 1 PRD (§2.6): "Moderation actions should be recorded internally (include the account of the moderator in the history)."

Only Administrators can read the log. Nobody can update or delete a log row, not even an Administrator: the table has no update or delete policy and no such grant. Rows are written by database triggers on the Submission table, so a moderation action can't happen without its log entry.

## Consequences

- The log must outlive what it describes. Rejected posts are deleted after 30 days (PRD §2.5) and Members can delete their own posts (PRD §2.4), so log rows can't depend on the post still existing. How much of a deleted post's text the log keeps is decided in the Freedom Wall database design.
- The log grows without limit. At chapter scale this is a few thousand rows a year, well within the Free Plan.
