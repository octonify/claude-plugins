# 0007. Local git hooks are feedback, not enforcement

**Status:** accepted
**Date:** 2026-08-16

## Context

`project-memory` installs a `commit-msg` hook that rejects commit subjects which do not follow
Conventional Commits. The hook file lives in a tracked directory, `.githooks/`, and is activated by
`git config core.hooksPath .githooks`. The tracked file is what makes the hook survive a clone; the
`git config` line is what makes it run.

That line is local configuration. It is not committed, and it does not travel with a clone. Every
other clone — a teammate's, a CI checkout, a fresh clone of one's own machine — receives the hook
file and no hook execution, with no warning of any kind. `git commit --no-verify` skips it even
where it has been configured. The failure is silent in both directions: nothing tells the person
who cloned that the hook is inert, and nothing tells the person who set it up that anyone else is
committing without it.

The consequence is delayed and hard to attribute. The plugin's history layer — decision trailers,
`git log --grep='^Decision:'`, the argument that git is a queryable event log rather than free text
— is worth exactly as much as the commit messages are disciplined. A single unconfigured clone
degrades that silently, and the first visible sign is a query that returns nothing, a year after the
commits it should have found were written.

Calling the hook "enforcement" is therefore a category error, and the plugin's own reference
material made it: the enforcement table listed the `commit-msg` hook as the mechanism that prevents
unusable commit messages. Nothing prevents them locally. Only a server-side check, over the commits
in a pull request, can do that.

## Decision

The `commit-msg` hook is documented as fast local feedback, never as enforcement. `init` says so in
three places, deliberately: in step 5, where the hook is installed and the question first arises; in
the generated `CLAUDE.md`, as one line under `## Commands` carrying the setup command, so a new
clone can find it without being told; and in `init`'s final report, as its own block rather than a
footnote.

Server-side validation in CI is **recommended and never shipped**. The plugin does not generate a
workflow file. CI shape is per-project, a generated workflow is the kind of file that gets merged
unread, and a check that blocks on day one against an existing backlog gets deleted rather than
satisfied. The recommendation, with its reasoning, lives in `reference/architecture.md` §6; `init`'s
report carries one sentence pointing at it.

## Consequences

- The enforcement table in `plugins/project-memory/reference/architecture.md` §6 changes meaning:
  the row for commit messages now reads "only in CI", and the `commit-msg` hook is named as
  feedback. The same row in `project-memory-structure-template.md` was corrected alongside it, since
  shipping a corrected template beside an uncorrected reference leaves the contradiction inside one
  plugin.
- Defect 6, when it trims the generated `CLAUDE.md`, **must not delete the `core.hooksPath` setup
  line.** It is one line, it is the only thing a new clone has to be told, and it is written under
  `## Commands` — inside a list that already exists — precisely so that a section-level trim does
  not take it.
- `audit` check 6 remains the only thing that detects an unconfigured clone, and it only runs where
  someone runs it. This is accepted: the alternative is shipping the CI workflow this record
  declines to ship.
