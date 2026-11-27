# AGENTS.md

Instructions for AI coding agents (Claude Code, Codex, OpenCode, Antigravity, Cursor, Copilot and others) and for people working on this repo.

This is the website for **Google Developer Groups on Campus – Mapúa University** (GDGoC Mapúa). **What to build:** the current Sprint 1 requirements are in [`resource/documentation/PRD/NEW/`](resource/documentation/PRD/NEW/). They take priority over the earlier [`GDGoC Website Plan.md`](resource/documentation/GDGoC%20Website%20Plan.md). **How it's built:** [`docs/proposals/0001`](docs/proposals/0001-freedom-wall-and-events.md) and the ADRs in [`docs/adr/`](docs/adr/). Domain terms are in [`GLOSSARY.md`](GLOSSARY.md).

## Repository

- Canonical repo: [`RedzerRiley/gdgoc-website-2526`](https://github.com/RedzerRiley/gdgoc-website-2526). Contributors work in forks and open PRs against it.
- Branches: `main` (production) and `dev` (integration). Base new work on the canonical `dev` and open PRs against `dev`. Maintainers promote `dev` to `main`.
- Remote names depend on how the repo was cloned. In a fork, `origin` is usually the fork and `upstream` is the canonical repo; in a direct clone, `origin` is the canonical repo. Check `git remote -v` before you push.

## Workflow (required)

Every agent follows [`docs/agents/workflow.md`](docs/agents/workflow.md). Read it before starting a task. In short:

0. **Review GitHub first, every session:** fetch all remotes, then report branch status, open PRs, CI and whether issues are on. This step only reports: pull, rebase or push only when the user asks.
1. **Pick the lane by size:**
   - trivial fix: implement, then verify, then ship;
   - one session: `grill-with-docs`, then `implement`;
   - several sessions: `grill-with-docs`, then `to-spec`, then `to-tickets`, then `implement` for each ticket;
   - a bug: `diagnosing-bugs`;
   - someone else's raw issue: `triage`.
2. **Verify** inside `gdgoc/`: `npm run lint` and `npm run build`. Add `npm test` once Vitest is set up.
3. **Ship:** open a PR against the canonical `dev` (the `pr` skill writes the body), then run `retro` after larger builds.

The skills are committed in `.agents/skills/` (Codex, OpenCode, Antigravity, Cursor, Copilot) and `.claude/skills/` (Claude Code), as two identical copies. [`docs/agents/workflow.md`](docs/agents/workflow.md) lists what each agent reads and how to work on a free tier. If your agent can't run skills, open `.agents/skills/<name>/SKILL.md` and follow it.

## Privacy and safety (required)

This site stores real students' data (names, emails, GDG IDs, campus and photos in Supabase). Every agent and contributor keeps that data out of anything that leaves their machine.

- **Secrets stay in `gdgoc/.env.local`.** Commit only `.env.example` with empty values. Keep secret keys out of all client code; only `NEXT_PUBLIC_*` publishable or anon keys belong in the browser. If a secret ever lands in a commit, tell the user right away so the key gets rotated. Deleting the line doesn't help, because it stays in git history.
- **Personal data stays out of the repo and out of AI prompts.** That covers code, docs, tests, fixtures, seed data, issues, tickets, PR bodies and commit messages. Use roles and fake placeholders (`Jane Doe`, `member@example.com`), never real member names, emails, IDs, phone numbers or photos. Real people's details belong only in Supabase, where the site loads them at runtime.
- **Query production data only when the user asks.** Read real member data only when the user asks for it, and only as much as the task needs. Never copy it into files, logs or tickets.
- **Treat every Supabase table as reachable by anyone.** All admin writes (officers, shop, ordering) and the sign-up insert run in the browser with the anon key. Row Level Security (RLS) policies are the only real protection. Any change to a table or a write path needs a matching RLS check, and hiding a button with `isAdmin` doesn't count as security.
- **Commit identity is the contributor's choice.** Your name, GitHub handle and commit email are public once pushed, and that's accepted here. If you'd rather keep your email private, use your GitHub `noreply` address (`<id>+<user>@users.noreply.github.com`). This applies only to your own identity: other people's personal data still stays out of commits.
- **Check every diff before pushing:** run `git diff --cached` and look for keys, tokens, `.env` files, personal data, screenshots of real accounts, and real names in test data.

## Layout

- `gdgoc/`: the Next.js app. **Run every npm command from here**, not from the repo root.
- `resource/documentation/`: planning and tech-stack docs (for reading only, not code). `PRD/NEW/` holds the current requirements; `PRD/OLD/` keeps earlier versions.
- `CODING_STANDARDS.md`: the rules `code-review` enforces.
- `docs/agents/`: the workflow, issue tracker, labels and domain-doc rules for agents.
- `.agents/skills/`, `.claude/skills/`: the committed workflow skills (two identical copies, pinned in `skills-lock.json`).
- `.gemini/settings.json`: makes the legacy Gemini CLI read `AGENTS.md`.
- `.github/workflows/docker-build.yml`: CI.

## Stack

Next.js 16 (App Router), React 19, TypeScript, Tailwind CSS v4, Supabase (auth, data and storage), Node 26 (the Docker base image).

## Commands (inside `gdgoc/`)

```bash
npm install     # first time
npm run dev     # dev server on http://localhost:3000
npm run build   # production build: run this to check your changes
npm run lint    # ESLint
```

There is no test suite yet.

## App structure (`gdgoc/src/app/`)

- `(main)/`: public pages (`about-us`, `events`, `shop`) and shared components (`NavBar`, `OfficerModal`, `UserProvider`).
- `(auth)/`: `login` and `sign-up`.
- `(admin)/`: admin route group (only a layout so far).
- `page.tsx`: redirects `/` to `/about-us`.
- `utils/supabase/`: the browser Supabase client (`client.ts`) and an auth `middleware.ts`.
- The import alias `@/*` points to `src/*`.

## Environment

Put the env vars in `gdgoc/.env.local`. It's gitignored, so never commit it. Ask a maintainer for the values.

```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=   # used by utils/supabase/client.ts
NEXT_PUBLIC_SUPABASE_ANON_KEY=                  # used by utils/supabase/middleware.ts
```

If these are missing, `client.ts` falls back to a placeholder client. Pages still render, but auth and data features stop working.

## Gotchas

- `utils/supabase/middleware.ts` is **not wired up**: no `src/middleware.ts` or `src/proxy.ts` imports it, so the session check it contains does not run, and the `(admin)` routes have no server-side guard.
- `next/image` loads remote images only from the Supabase public storage host listed in `gdgoc/next.config.js`. Add any new image host there.
- The two Supabase key variables above have different names. Set both.

## CI

`agent-skills.yml` fails any PR where `.agents/skills/` and `.claude/skills/` differ.

Every push to `main` or `dev` builds the Docker image from `gdgoc/Dockerfile` and pushes it to GitHub Container Registry (`ghcr.io/<owner>/<repo>`). Make sure `npm run build` passes before you push.

## Agent workflows

These files tell agents where issues live and how to use project docs. Any agent can read them; they don't depend on a particular tool.

### Issue tracker

For now, tickets are local markdown files under `.scratch/` (gitignored) because issues are off on the canonical repo. Once they're turned on, tickets move to GitHub issues on `RedzerRiley/gdgoc-website-2526`. See [`docs/agents/issue-tracker.md`](docs/agents/issue-tracker.md).

### Triage labels

The five triage stages use plain-English labels: `needs review`, `needs more info`, `ready for AI`, `ready for a person`, `won't do`. See [`docs/agents/triage-labels.md`](docs/agents/triage-labels.md).

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root, created when first needed. See [`docs/agents/domain.md`](docs/agents/domain.md).
