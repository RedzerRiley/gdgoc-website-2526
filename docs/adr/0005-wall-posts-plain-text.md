---
status: proposed
---

# Freedom Wall posts are plain text only

A Wall Post is plain text of 1 to 2,000 characters with one Topic, as the Sprint 1 PRD (§2.2) requires. No Markdown, HTML, rich text, images, GIFs, background colors or stickers. The database enforces the length and the Topic list, not just the form.

This replaces the earlier plan (Website Plan items 6 and 7, and the first version of proposal 0001) of colored posts with images and stickers. Plain text removes the hardest moderation problem, harmful images, along with the private image bucket, upload shrinking and storage cost it needed.

## Consequences

The page renders post text as text, never as HTML, so there is nothing to sanitise beyond normal escaping. Adding images or stickers later means a new ADR, a private bucket with review-gated access, and storage budget on the Free Plan.
