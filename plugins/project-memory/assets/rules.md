# Documentation methodology — project-memory

How the documentation in this repository is maintained. Installed by the `project-memory` plugin
as `.claude/rules/project-memory.md`; these rules apply when creating or editing `CLAUDE.md`,
anything under `docs/knowledge/` or `docs/decisions/`, or this file.

They are conventions with, at most, optional enforcement: the `commit-msg` hook runs only in
clones that configured `core.hooksPath` and is skipped by `--no-verify`, and the file-protection
hook exists only where its install was accepted. A rule being unenforced somewhere does not make
it optional; being written down here is what it has.

## Rules

1. Budgets: `CLAUDE.md` 200 lines, `docs/knowledge/*.md` 150 lines, ADRs 60 lines,
   `.claude/rules/*.md` 100 lines. Over budget means split by topic or delete.
2. Accepted decision records are never edited, with one exception: a dated, append-only note
   under a trailing `## Notes` heading, recording a later observation or correcting a claim in
   Context or Consequences that turned out to be false. A note may never change the Decision —
   that still requires a superseding record. Nothing above `## Notes` is ever edited.
3. Every non-obvious claim carries `[F]` fact / `[I]` inference / `[U]` unverified, plus a source
   and a date: `[F, src/config/loader.ts:88, 2026-08-16]`. A `[F]` source must be something a
   reader can re-check mechanically: a file path, a path with a line number, or a command that
   can be run. An absence is cited as the runnable check that establishes it —
   `[F, no tsconfig.json at repo root, 2026-08-16]` — never as a description of having looked
   ("repo root listing" names what was done, not what to check). If the source cannot be written
   that way, the claim is `[I]`.
4. Contradictions go to `docs/knowledge/07-open-questions.md`. Do not resolve by guessing; the
   disagreement is the finding.
5. Do not document what can be derived from the code. No directory listings, no dependency lists.
6. Commits follow Conventional Commits. Non-obvious implementation choices get a `Decision:`
   trailer instead of a file.
7. Create a knowledge file the day it has real content, not before.

## Conventions

- Confidence markers: `[F]` fact, stated in a named source · `[I]` inference drawn from sources
  but not stated in them · `[U]` unverified.
- Knowledge files carry a frontmatter header: `as_of`, `basis_commit`, `owner`, `review_trigger`,
  `covers_paths`. `review_trigger` is an event, not a date; `covers_paths` is the list of globs
  the drift check compares against.
