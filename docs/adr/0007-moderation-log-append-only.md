---
status: accepted
---

# The moderation log is append-only

Every approve, reject, edit and delete of a Submission writes one row to `freedom_wall_moderation_logs`: the action, the time, the Administrator's account, the rejection reason if any, and for an edit the Topic before and after. When a Member deletes their own post, the row records no account. This meets the Sprint 1 PRD (§2.6): "Moderation actions should be recorded internally (include the account of the moderator in the history)."

Only Administrators can read the log, through `admin_list_freedom_wall_moderation_logs()`. Nobody using the website can update or delete a log row, not even an Administrator: the website roles have no grant on the table at all.

Each moderation function writes its own log row in the same transaction as the change. We chose this over database triggers on the Submission table because the website can't reach the Freedom Wall tables directly: every approve, reject, edit and delete goes through one of these functions, so none can happen without its log row. A function also knows things a trigger doesn't, such as which action was meant (to a trigger, an Administrator's delete and a Member's delete are both just a deleted row). The pgTAP tests check that every action writes exactly one row with the acting Administrator.

## Consequences

- The log must outlive what it describes. Rejected posts are deleted after 30 days (PRD §2.5) and Members can delete their own posts (PRD §2.4), so log rows can't depend on the post still existing. The log never stores a post's message or its author, so neither outlives a deleted post.
- Changes made outside the website (the SQL editor or the service role key) skip the functions and aren't logged. Only the project owner has those.
- A new moderation function must write its own log row and get a test for it. Forgetting is the main risk of this choice.
- The log grows without limit. At chapter scale this is a few thousand rows a year, well within the Free Plan.
