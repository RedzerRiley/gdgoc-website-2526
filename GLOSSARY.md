# GDGoC Mapúa Website

The public website of Google Developer Groups on Campus – Mapúa University: chapter info, events, a shop, and community spaces where members post content that Administrators review.

Feature scope comes from the Sprint 1 PRD in `resource/documentation/PRD/NEW/`. These terms follow its wording.

## People

**Member**:
A person with a signed-in account on the site.
_Avoid_: User (when meaning a person), account, student

**Administrator** (Admin):
A Member with admin rights who manages site content and reviews Submissions. Stored as `Users.is_admin` and checked by `private.is_admin()`.
_Avoid_: Moderator, officer (when meaning the permission)

**Officer**:
A chapter officer whose profile is shown on the Officers and Members page. Being an Officer grants no permissions; that's what being an Administrator means.
_Avoid_: Administrator, admin

**Member directory**:
The list of Members that signed-in Members can browse. It shows only profile fields (name, photo, role, department, links, bio) and never the GDG ID.
_Avoid_: User list, roster

## Events

**Event**:
A chapter activity in one of the four Event categories, published on the Events page.
_Avoid_: Activity, session (when meaning the whole event)

**Event category**:
The kind of Event: Workshop, Hackathon, Talk or Social.
_Avoid_: Type, tag

**Publish status**:
Where an Event or Announcement stands for the public, set by an Administrator: _draft_, _published_, _unpublished_ or _archived_. Only published items are public.
_Avoid_: Visibility, state

**Event timing**:
_Upcoming_ (not started), _Ongoing_ (started, not ended) or _Completed_ (ended). Follows from the start and end time alone and is never set by hand. Coming Soon lists Upcoming and Ongoing Events; Previous Events lists Completed ones.
_Avoid_: Current event, past event, coming soon (as a status)

**Registration status**:
Whether an upcoming Event takes registrations: _not open yet_, _open_ or _closed_. Set by an Administrator, with an optional closing time that closes it automatically. Together with Event timing it produces the PRD's status labels (Upcoming, Registration Open, Registration Closed, Ongoing).
_Avoid_: Status (on its own)

**Featured event**:
The one optional Event an Administrator has picked to headline the Events page. At most one at a time.
_Avoid_: Highlight, pinned event

**Timeline**:
The ordered schedule of an Event: time, title and description for each item.
_Avoid_: Agenda, program

**Gallery**:
The extra photos attached to an Event, in order.
_Avoid_: Album

## Freedom Wall

**Wall Post**:
A Submission to the Freedom Wall: plain text of up to 2,000 characters with one Topic, optionally Anonymous.
_Avoid_: Message, note, confession

**Topic**:
The label of a Wall Post: General, Project/Collaboration, Tech Tips, Hackathon, Shoutout or Questions.
_Avoid_: Category (for Wall Posts), tag

**Reaction**:
One of five responses a Member can give a Wall Post once each: Love, Ship It, Lit, Relatable, Tech.
_Avoid_: Like, emoji

**Submission**:
Any content a Member sends in that an Administrator has to review before the public can see it. Today that's a Wall Post.
_Avoid_: Entry, request

**Review status**:
Where a Submission stands: _pending_ (waiting for review; a Member may have one at a time), _approved_ (public) or _rejected_ (never shown, kept 30 days, then deleted).
_Avoid_: State, visibility

**Anonymous**:
A Submission that hides its author's name from the public. Administrators can still see who wrote it.
_Avoid_: Private, hidden

**Moderation log**:
The internal, append-only record of every approve, reject, edit and delete, with the Administrator who did it.
_Avoid_: History (on its own), audit (as a noun)

**Notification**:
An in-app message telling a Member that their Submission was approved or rejected.
_Avoid_: Alert, email

## Announcements

**Announcement**:
A Markdown post on the Announcement Board, written by an Administrator, with a category and optional attachments.
_Avoid_: News, post (on its own)

**Pinned announcement**:
An Announcement shown in the featured section at the top of the board.
_Avoid_: Featured event (that's for Events)
