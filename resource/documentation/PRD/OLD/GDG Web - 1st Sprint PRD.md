# Product Requirements Document

## GDG Mapúa University Website — New Pages

# **1\. Events Page**

## **1.1 Page Structure**

Two sections:

* **Coming Soon** — Announced and upcoming events.  
* **Previous Events** — Completed events.

## **1.2 Coming Soon**

Each event entry must include:

| Field | Description |
| :---: | :---: |
| Event Title | Name of the event |
| Cover Image | Event poster or promotional image |
| Description | Short event overview |
| Date | Event date or date range |
| Time | Start and end time |
| Venue | Physical or online location |
| Timeline | Event schedule and activities |
| Registration URL | External registration link |
| Status | Upcoming, Registration Open, Registration Closed, Ongoing |

**Interactions:**

* Clicking an event opens its detailed view.  
* Clicking Register opens the registration form/URL in a new tab.  
* Register is disabled when registration is closed.  
* Events are displayed chronologically, nearest upcoming first.

## **1.3 Previous Events**

Each entry must include:

| Field | Description |
| :---: | :---: |
| Event Title | Name of the event |
| Cover Image | At least one event photograph or poster |
| Description | Event overview or recap |
| Date | Date the event occurred |
| Venue | Event location |
| Timeline | Event schedule |
| Photo Gallery | Additional event photographs |

**Interactions:**

* Clicking an event opens its detailed view.  
* Events are sorted newest first.  
* Users can filter by year and category.  
* Users can search by event title.

## **1.4 Admin Panel**

Administrators can:

* Create, edit, and delete events.  
* Upload cover images and gallery photographs.  
* Add and edit event descriptions.  
* Configure event dates, times, and venues.  
* Add and edit event timelines.  
* Set registration URLs.  
* Update event statuses.  
* Publish, unpublish, and archive events.

# **2\. Freedom Wall**

## **2.1 Page Structure**

* Public Freedom Wall feed.  
* Submission composer.  
* Topic filters.  
* Search bar.  
* User submission history (authenticated users).

Anyone can view approved posts. Authentication is required to submit.

## **2.2 Submission Composer**

| Field | Requirements |
| :---: | :---: |
| Message | Plain text only |
| Character Limit | 2000 characters |
| Topic | Required; selected from predefined labels |
| Identity | Anonymous or Non-anonymous |

**Topic Labels:**

* General  
* Project/Collaboration  
* Tech Tips  
* Hackathon  
* Shoutout  
* Questions

**Interactions:**

* Display a live character counter.  
* Prevent empty submissions.  
* Require topic selection.  
* Allow users to toggle anonymous posting.  
* Require login before submission.  
* Display a confirmation after successful submission.

**Content Restrictions:**

* No Markdown.  
* No HTML.  
* No rich-text formatting.  
* No file attachments.

## **2.3 Submission Workflow**

1. User composes a post.  
2. User selects a topic.  
3. User selects anonymous or non-anonymous posting.  
4. User submits the post.  
5. Submission enters Pending status.  
6. Administrators review the submission.  
7. Administrator approves or rejects it.  
8. User receives a notification regarding the decision.

## **2.4 Freedom Wall Feed**

Each published post must display:

| Field | Description |
| :---: | :---: |
| Author | Display name or Anonymous |
| Topic | Selected topic label |
| Message | Published content |
| Date Posted | Publication date and time |
| Reaction | Displays the number of each reaction |

**Interactions:**

* Display approved posts only.  
* Sort newest first (default) or by popularity (no. of reactions).  
* Filter by topic.  
* Search by keywords.  
* Authenticated users can view their own submission history and statuses.

**Reactions:**

* Love ❤️  
* Ship It 🚀   
* Lit 🔥   
* Relatable ☕   
* Tech 🤖 

## **2.5 Submission Statuses**

| Status | Behavior |
| :---: | :---: |
| Pending | Awaiting administrator review |
| Approved | Published on the Freedom Wall |
| Rejected | Not publicly visible; user is notified |

## **2.6 Admin Panel — Moderation**

**Pending Submissions**

Administrators can:

* View submitted messages.  
* View the submitter's account information.  
* See the selected topic.  
* See whether the submission is anonymous.  
* Approve or reject submissions.  
* Provide a rejection reason.

**Approved Submissions**

Administrators can:

* View published posts.  
* Edit posts.  
* Delete posts.

**Rejected Submissions**

Administrators can:

* View rejected submissions.  
* View rejection reasons.  
* Review submission history.

**Rules:**

* Anonymous posts must hide the user's identity publicly.  
* Administrators must still be able to identify anonymous submitters.  
* Edited posts retain their original author attribution.  
* Deleted posts must disappear from the public feed.  
* Moderation actions should be recorded internally (include the account of the moderator in the history).

## **2.7 Notification System**

Users must receive in-app notifications when their submissions are approved or rejected.

Each notification must contain:

* Notification title.  
* Notification message.  
* Date and time.  
* Read/unread status.  
* Link to the relevant submission or submission status.

**UI Requirements:**

* Notification bell in the navigation bar.  
* Unread notification counter.  
* Notification dropdown and dedicated page.  
* Mark as read functionality.

# **3\. Announcement Board**

## **3.1 Page Structure**

* Featured/Pinned Announcement.  
* Announcement Feed.  
* Category Filters.  
* Search Bar.

All published announcements are publicly accessible. Only administrators can create and manage announcements.

## **3.2 Announcement Fields**

| Field | Requirements |
| :---: | :---: |
| Title | Required announcement headline |
| Content | Required; Markdown supported |
| Category | Required; selected from predefined categories |
| Date Posted | Automatically generated upon publication |
| Author | Publishing administrator |
| Attachments | Optional images and PDF files |
| Featured/Pinned | Optional |

**Suggested Categories:**

* General  
* Events  
* Recruitment  
* Opportunities

## **3.3 Announcement Content**

Supported Markdown:

* Headings  
* Bold and italic text  
* Ordered and unordered lists  
* Links  
* Blockquotes  
* Inline code  
* Tables

Provide a Markdown editor with a live preview.

Sanitize rendered Markdown to prevent script injection.

## **3.4 Announcement Feed**

Each announcement card must display:

* Title.  
* Content preview.  
* Category label.  
* Date posted.  
* Author.  
* Pinned indicator, if applicable.

Pinned announcements are brought to the top of the feed.

**Interactions:**

* Clicking an announcement opens its full details.  
* Search by title or content.  
* Filter by category.  
* Sort by newest (default) or oldest.  
* Pinned announcements appear in a separate featured section.

## **3.5 Announcement Details**

Display:

* Full title.  
* Complete Markdown-rendered content.  
* Category.  
* Date posted.  
* Last updated date, if edited.  
* Author.  
* Attachments.

## **3.6 Admin Panel**

Administrators can:

* Create announcements.  
* Edit announcements.  
* Delete announcements.  
* Save announcements as drafts.  
* Publish and unpublish announcements.  
* Preview announcements before publishing.  
* Upload attachments.  
* Assign categories.  
* Pin and unpin announcements.  
* Archive and unarchive announcements.

## **3.7 Announcement Statuses**

| Status | Description |
| :---: | :---: |
| Draft | Saved but not publicly visible |
| Published | Visible on the Announcement Board |
| Archived | Removed from the active feed but retained in the archive |
| Unpublished | Hidden from public view |

# **4\. Officers and Members Page**

## **4.1 Page Structure**

* Executive Officers directory.  
* Core Team & Committee Leads list.  
* General Member directory.  
* Search bar and filtering controls.

## **4.2 Profile Details & Directory**

Each member profile card displays:

| Field | Description |
| :---: | :---: |
| Full Name | Member’s name/display name |
| Profile Photo | Headshot or custom avatar |
| Role / Position | Official title or membership level |
| Department | e.g., Communications, Public Relations, Tech, Operations, etc. |
| Social & Professional Links | LinkedIn, GitHub, or portfolio URLs |
| Bio | Brief personal description |

## **4.3 Roles and Permissions**

* **Public Visitors:** Can view officer profiles.  
* **Authenticated Members:** Can edit their own bio and social links; View member directory.  
* **Administrators:** Can assign roles, update committee placements, and manage member statuses.

# **5\. General Requirements**

## **5.1 Access Control**

| Feature | Visitor | Authenticated User | Admin |
| :---: | :---: | :---: | :---: |
| View Events | Yes | Yes | Yes |
| Manage Events | No | No | Yes |
| View Freedom Wall | Yes | Yes | Yes |
| Submit Freedom Wall Post | No | Yes | Yes |
| Manage Freedom Wall Posts | No | No | Yes |
| View Announcements | Yes | Yes | Yes |
| Manage Announcements | No | No | Yes |

## 

## 

## **5.2 Design Requirements**

Follow the existing website's design system and the attached visual references.

* Dark theme.  
* Purple/black backgrounds.  
* Google rainbow accent colors.  
* Rounded cards and containers.  
* Consistent typography and spacing.  
* Responsive layouts for desktop, tablet, and mobile.  
* Consistent navigation and interactive states.

## **5.3 General Technical Requirements**

* Integrate with the existing authentication system.  
* Implement role-based access control.  
* Validate all user inputs on the backend.  
* Sanitize user-generated content.  
* Implement appropriate loading, empty, and error states.  
* Ensure uploaded images and documents are properly validated.  
* Restrict admin operations to authorized accounts.  
* Store timestamps consistently and display them in Philippine Standard Time (PHT).