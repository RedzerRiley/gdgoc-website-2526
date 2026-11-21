# Issue tracker

**Active mode: local markdown.** Issues are turned off on `RedzerRiley/gdgoc-website-2526` for now, so specs and tickets live as markdown files under `.scratch/`. That folder is gitignored and private to each contributor.

**Switch to GitHub** once a repo admin turns on issues for `RedzerRiley/gdgoc-website-2526` (Settings → Features → Issues) and creates the triage labels (see `triage-labels.md`). To switch, replace the body of this file with [`issue-tracker-github.md`](issue-tracker-github.md), and move any open `.scratch/` tickets that still matter to GitHub issues.

Always check: `gh api repos/RedzerRiley/gdgoc-website-2526 -q .has_issues`. If it prints `true` while this file still says local, tell the user that the switch is due.

## Local markdown conventions

Issues and specs for this repo live as markdown files in `.scratch/`.

### Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file
- Triage state is recorded as a `Status:` line near the top of each issue file, using the label strings in `triage-labels.md` (for example `Status: ready for AI`)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

### When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

### When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.
