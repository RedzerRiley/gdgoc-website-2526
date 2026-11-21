# Issue tracker: GitHub (target mode)

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create -R RedzerRiley/gdgoc-website-2526 --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view -R RedzerRiley/gdgoc-website-2526 <number> --json number,title,body,labels,comments`.
- **List issues**: `gh issue list -R RedzerRiley/gdgoc-website-2526 --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Make an issue a sub-issue of a parent**: `gh issue create -R RedzerRiley/gdgoc-website-2526 --parent <parent> ...`, or `gh issue edit -R RedzerRiley/gdgoc-website-2526 <parent> --add-sub-issue <child>` afterwards (`gh` 2.94+). Older `gh`: `gh api --method POST repos/RedzerRiley/gdgoc-website-2526/issues/<parent>/sub_issues -F sub_issue_id=<child-db-id>` (database id, as in **Blocking** below). Without sub-issues, put `Part of #<parent>` at the top of the child body.
- **Comment on an issue**: `gh issue comment -R RedzerRiley/gdgoc-website-2526 <number> --body "..."`
- **Apply / remove labels**: `gh issue edit -R RedzerRiley/gdgoc-website-2526 <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close -R RedzerRiley/gdgoc-website-2526 <number> --comment "..."`

Always target the canonical repo **RedzerRiley/gdgoc-website-2526** explicitly with `-R RedzerRiley/gdgoc-website-2526`. This works the same from a clone of upstream or a clone of any contributor's fork, whatever the remotes are named.


## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage` reads this flag.)_

When set to `yes`, PRs run through the same labels and states as issues, using the `gh pr` equivalents:

- **Read a PR**: `gh pr view -R RedzerRiley/gdgoc-website-2526 <number> --comments` and `gh pr diff -R RedzerRiley/gdgoc-website-2526 <number>` for the diff.
- **List external PRs for triage**: `gh api --paginate 'repos/RedzerRiley/gdgoc-website-2526/pulls?state=open' --jq '.[] | select(.author_association | IN("OWNER","MEMBER","COLLABORATOR") | not) | {number, title, author: .user.login, author_association, labels: [.labels[].name]}'`.
- **Comment / label / close**: `gh pr comment -R RedzerRiley/gdgoc-website-2526`, `gh pr edit -R RedzerRiley/gdgoc-website-2526 --add-label`/`--remove-label`, `gh pr close -R RedzerRiley/gdgoc-website-2526`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be either: resolve with `gh pr view -R RedzerRiley/gdgoc-website-2526 42` and fall back to `gh issue view -R RedzerRiley/gdgoc-website-2526 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Read it as in **Read an issue** above.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: a single issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body. `gh issue create -R RedzerRiley/gdgoc-website-2526 --label wayfinder:map`.
- **Child ticket**: an issue linked to the map as a GitHub sub-issue (see **Make an issue a sub-issue of a parent**). Where sub-issues aren't enabled, add the child to a task list in the map body and put `Part of #<map>` at the top of the child body. Labels: `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: GitHub's **native issue dependencies**, the canonical, UI-visible representation. Add an edge with `gh api --method POST repos/RedzerRiley/gdgoc-website-2526/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where `<blocker-db-id>` is the blocker's numeric **database id** (`gh api repos/RedzerRiley/gdgoc-website-2526/issues/<n> --jq .id`, _not_ the `#number` or `node_id`). GitHub reports `issue_dependencies_summary.blocked_by` (open blockers only, the live gate). Where dependencies aren't available, fall back to a `Blocked by: #<n>, #<n>` line at the top of the child body. A ticket is unblocked when every blocker is closed.
- **Frontier query**: list the map's open children (`gh issue list -R RedzerRiley/gdgoc-website-2526 --state open`, scoped to the map's sub-issues / task list), drop any with an open blocker (`issue_dependencies_summary.blocked_by > 0`, or an open issue in the `Blocked by` line) or an assignee; first in map order wins.
- **Claim**: `gh issue edit -R RedzerRiley/gdgoc-website-2526 <n> --add-assignee @me`, the session's first write.
- **Resolve**: `gh issue comment -R RedzerRiley/gdgoc-website-2526 <n> --body "<answer>"`, then `gh issue close -R RedzerRiley/gdgoc-website-2526 <n>`, then append a context pointer (gist + link) to the map's Decisions-so-far.
