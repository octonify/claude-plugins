# Changelog — project-memory

All notable changes to this plugin. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The `version` field in `.claude-plugin/plugin.json` must be bumped in the same commit as any entry
below. Without that bump, no installed user receives the change.

## [Unreleased]

Not released. `version` in `.claude-plugin/plugin.json` is deliberately still `0.1.0`; these
changes reach no installed user until it is bumped.

### Fixed

- `check-docs.sh` reported success without having compared anything. `resolve_base()` accepted the
  currently checked-out branch as a base, so in a repository with no remote whose branch is
  `master` it resolved to `master`, `git diff master...HEAD` was empty by construction, and the
  script printed "nothing to check" and exited 0 forever. A base ref that is the checked-out
  branch, or that points at `HEAD`, is now rejected as the tautology it is, and a run with no
  usable base exits **2** — naming every candidate tried and why each was rejected. Exit 2 is
  independent of `STRICT`, because an inability to run is not a finding.
- `check-docs.sh` now names the base ref on every run, on success and on failure alike, and says
  `no drift against <base>` on a clean run. Silence about the base is how the defect hid.
- An explicit base argument that cannot serve as a base is now an error rather than a reason to
  fall back to the default chain.
- `check-docs.sh` exited 0 with an empty diff when the base and `HEAD` had no common ancestor,
  which reads as "no changes". It now exits 2.

### Changed

- `init` states in its final report that `core.hooksPath` is local config, that the hook is active
  in that clone only, that every other clone needs `git config core.hooksPath .githooks`, and that
  the line is written down in `CLAUDE.md`. A local hook is fast feedback, not enforcement, and the
  report now says that too.
- The generated `CLAUDE.md` carries the setup line, one line, under `## Commands`.
- `init` explains the new exit 2 from `check-docs.sh`, which is the expected first run on a
  freshly scaffolded repository whose only branch is the one checked out.
- `reference/architecture.md` documents the exit-code contract of both scripts, corrects the
  enforcement table row for the `commit-msg` hook, and recommends — without shipping — a CI check
  on commit subjects.

## [0.1.0] — 2026-08-16

Initial release. **Experimental.** The structure this plugin installs has not been validated on a
real project over time; the version number says so deliberately.

### Added

- `init` skill: scaffolds `CLAUDE.md`, `docs/knowledge/03-architecture.md` and
  `docs/knowledge/07-open-questions.md`, installs the `commit-msg` hook via `core.hooksPath`, and
  installs `check-docs.sh` and `check-staleness.sh` as non-blocking warnings. Offers, but does not
  create, the remaining knowledge files, the agent hooks, and the `refs/notes/*` fetch refspec.
- `audit` skill: read-only health report covering budgets, staleness headers, `covers_paths`
  pointing at absent paths, unsourced claims, Conventional Commits adherence, whether
  `core.hooksPath` and the notes refspec are actually configured, filename honesty, and decision
  record integrity. Ends with the five-minute recovery test.
- Assets: `commit-msg`, `check-docs.sh`, `check-staleness.sh`, `protect-files.sh`,
  `settings.json.fragment`, and templates for `CLAUDE.md`, architecture, open questions, sources
  and ADRs.
- `reference/architecture.md`: the reasoning behind the structure, loaded only when a default has
  to be adapted or defended.

### Notes on the shipped scripts

The scripts in the source template were illustrative and had never been run. Fixes made while
turning them into real files are listed in the repository's initial commit and summarised here:

- `check-staleness.sh` ended on a `[ ... ] && echo ...` test, so it exited non-zero whenever the
  last document was *not* stale. It now ends with an explicit `exit 0`.
- Both checks died under `set -e` when the docs directory was empty or the base ref did not exist.
  They now resolve a base ref by fallback and report "nothing to check".
- `check-docs.sh` parsed `covers_paths` without bounding the scan to the YAML frontmatter, so every
  markdown bullet in a document body was treated as a covered path whenever `covers_paths` was the
  last frontmatter key.
- `check-docs.sh` matched an unbounded `**` pattern against every changed file. Such patterns are
  now reported and skipped.
- Both checks were blocking by default. They now warn and require `STRICT=1` to fail.
- `commit-msg` read `head -n1` directly, so a `\r` from a Windows checkout was counted in the
  72-character limit, and a comment or blank first line became the subject. It now strips comments,
  blanks and CR before matching, and lets `fixup!`/`squash!` through.
- The template said only `chmod +x`. On Windows that does not reach git's index, so hooks and
  scripts were committed `100644` and silently never ran in a fresh clone on Linux or macOS. The
  `init` skill now also runs `git add --chmod=+x`, and `audit` checks the index mode. This was
  found by running `audit` against the repository `init` had just scaffolded.
- The template said nothing about line endings in the target repository. `init` now pins
  `*.sh` and `.githooks/*` to `eol=lf` in the target's `.gitattributes`.
- `protect-files.sh` assumed `jq` was installed; a missing `jq` produced exit 127, which is neither
  block nor allow. It now falls back to a `sed` extraction and degrades to allow. It also
  normalises backslashes so Windows paths match the protected patterns.

[0.1.0]: https://github.com/octonify/claude-plugins/releases/tag/project-memory--v0.1.0
