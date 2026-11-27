# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker (GitHub issues on `RedzerRiley/gdgoc-website-2526`). The labels are plain English so every teammate can read them at a glance.

| Label in mattpocock/skills | Label in our tracker | Meaning                                              |
| -------------------------- | -------------------- | ---------------------------------------------------- |
| `needs-triage`             | `needs review`       | Someone needs to look at this and decide what to do  |
| `needs-info`               | `needs more info`    | Waiting for the reporter to explain more             |
| `ready-for-agent`          | `ready for AI`       | Fully explained; an AI agent can do it alone         |
| `ready-for-human`          | `ready for a person` | Needs a person to build it                           |
| `wontfix`                  | `won't do`           | We decided not to do this                            |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table. The labels contain spaces, so always quote them: `--add-label "ready for AI"`.

Edit the "Label in our tracker" column to match whatever vocabulary you actually use.

## Creating the labels (repo admin, one time)

```bash
R=RedzerRiley/gdgoc-website-2526
gh label create "needs review"       -R $R --color FBCA04 --description "Someone needs to look at this and decide what to do"
gh label create "needs more info"    -R $R --color D876E3 --description "Waiting for the reporter to explain more"
gh label create "ready for AI"       -R $R --color 0E8A16 --description "Fully explained; an AI agent can do it alone"
gh label create "ready for a person" -R $R --color 1D76DB --description "Needs a person to build it"
gh label create "won't do"           -R $R --color CCCCCC --description "We decided not to do this"
```
