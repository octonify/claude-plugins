# Changelog — project-memory

All notable changes to this plugin. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The `version` field in `.claude-plugin/plugin.json` must be bumped in the same commit as any entry
below. Without that bump, no installed user receives the change.

## [Unreleased]

0.2.0's four shipped scripts were verified on Linux after release, 2026-08-16: GNU bash 5.2.21,
git 2.43.0, GNU sed 4.9, with `jq` present and absent. Every verdict, exit code and message
matched the Windows transcripts, including detached HEAD, a repository path containing a space,
and three locales. The scripts run were verified byte-identical to the `project-memory--v0.2.0`
tag. macOS remains untested.

### Added

- `init` now creates `docs/decisions/` and a first record, ADR 0001 — the target project's own
  decision to adopt this structure, written from what the survey learned about that repository,
  in Nygard format and under the 60-line budget, with paragraph Context. Before this, five
  shipped artifacts promised a decision-record layer — the `CLAUDE.md` routing table, the
  architecture template's §9, `protect-files.sh`'s `PROTECTED` list, `adr-template.md`, and
  `init`'s own `description` — and nothing delivered it. If the survey cannot learn enough to
  write real Context, `init` says so and records the gap in `07-open-questions.md` instead of
  inventing a rationale.
- `init`'s step 9 report offers, ready to paste, the `Decision:` trailer for the commit the user
  is about to make, naming the adaptations the run actually made to shipped defaults. `init` does
  not commit, so it cannot write the trailer itself; adaptations of that size are trailer
  material, not ADR material. If no adaptations were made, it says so instead of emitting an
  empty template.
- `init` step 4 may offer — never write unasked — ADR 0002 for one non-obvious, undocumented
  choice the survey noticed, asking the user why it was made. If the user does not answer,
  nothing is written and the question goes to `07-open-questions.md`. One offer at most.

### Changed

- **`init` no longer creates a `scripts/` directory.** `check-docs.sh` and `check-staleness.sh`
  now install into `.githooks/`, next to the `commit-msg` hook they belong with. Many projects
  already own `scripts/` for build and deploy tooling; writing documentation checks into it was
  both a name collision and a conceptual muddle. The only top-level directory `init` now creates
  unconditionally is `.githooks/`; an existing `docs/` is used rather than duplicated, and a
  project with `documentation/` or `doc/` instead still gets `docs/` — the path the checks depend
  on is constant, and the report says so. Scaffolds made by older versions keep their `scripts/`
  layout and keep working; the scripts never hardcoded their own location.
- The `.gitattributes` lines `init` appends now name only paths this plugin writes —
  `.githooks/*` and `.claude/hooks/*.sh` — instead of a bare `*.sh`, which set line-ending policy
  for the project's own scripts.
- The generated `CLAUDE.md` routing table now carries two tooling rows, written from where the
  run actually put the checks, and **`audit` locates both scripts through the routing table
  instead of a hardcoded path**. A row that names a path with nothing at it is a high-severity
  finding, not "not applicable"; a script found at a historical location with no row is run and
  reported as unrouted; "not applicable" is reserved for a repository whose table names no
  tooling and has none installed. Without this, the layout move itself would have made `audit`
  report the drift check as not applicable — a check quietly going blind because a path moved
  underneath it.
- `audit` check 8 states the one exception to decision-record immutability — a dated, append-only
  note under a trailing `## Notes` heading — and how to check it mechanically with
  `git diff <adding-commit>..HEAD`, so a legitimate note is not reported as a modified accepted
  record forever.
- `CLAUDE.md.template` hard rule 2 carries the same exception, so the convention the plugin
  teaches matches the one this repository follows. A note may never change the Decision; that
  still requires a superseding record.
- `init` step 3's routing-table instruction is now generative rather than subtractive: the table
  is built from the file set the run actually created, not copied from the template and trimmed.
  The old wording — "include only rows whose target file exists" — contradicted the template it
  applied to for as long as `docs/decisions/` was never created.
- `init` step 3's ADR 0001 spec now requires that at least one consequence name something true
  only in the target repository. The previous wording, "what now has to be maintained", invited a
  generic list, and the first real ADR produced under it came out roughly one sentence in five
  specific to its repository.
- `audit` check 3a no longer rates every drift-check exit 2 as high severity. When the script's
  own stderr says the repository has one branch and no remote — so no base ref can exist yet —
  the finding is reported at low severity instead: nothing there is silently unenforced, because
  the script said out loud that it compared nothing. The finding itself still appears; every
  other exit-2 reason stays high. Before this, a user running `audit` the day after `init` got a
  high-severity finding the scaffold had told them to expect.
- `reference/architecture.md` §3 records, next to the "no trigger, no document" guard, why a
  shipped promise with nothing behind it is a finding rather than an argument for creating the
  promised file, and why ADR 0001 was the one exception.

## [0.2.0] — 2026-08-16

Fixes to the shipped scripts. Nothing in this release changes the shape of what `init` writes.
The design remains unvalidated on a real project over time; the version stays below `1.0.0`
deliberately.

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
- `check-docs.sh` ran `git diff` with stderr discarded and its exit status thrown away, so any
  failure of the diff left the changed-file list empty and the run printed "no changes, nothing to
  check" and exited 0 — one line below the guard added above to prevent exactly that. The status is
  kept, git's own message is shown, and a failed diff exits 2.
- `check-docs.sh` skipped in silence any knowledge document whose `covers_paths` could not be
  parsed, which is indistinguishable from a document that never opted in. Every unchecked document
  is now named on stderr, and a key that is present but unreadable is reported as a broken opt-in
  and counts as a finding. The YAML flow form `covers_paths: [src/**]` is now parsed rather than
  silently discarded.
- `check-docs.sh` matched a `covers_paths` prefix anywhere in a changed path, so `src/api/**`
  reported drift for a change to `vendor/foo/src/api/x.ts`. The match is anchored to the start of
  the path, with the prefix escaped so a literal `.` is not a wildcard.
- `check-staleness.sh` absorbed a failing `git rev-list --count` with `|| echo 0`, recording the
  document as zero commits behind — the healthiest result it can report. A failed count is now
  named as `UNCOUNTABLE`, with git's message, and no value is substituted. An empty or non-numeric
  count no longer produces a bash syntax error that skipped the document inside an exit-0 run.
- `protect-files.sh` allowed a write in silence when it could not read the tool input. It still
  allows — a protection hook that cannot read its input must not block every edit — but it now says
  so on stderr, in different words for the `jq` path and the fallback path.
- Without `jq`, `protect-files.sh` allowed writes to protected files whenever the path arrived
  JSON-escaped — every Windows path does — because the `sed` fallback kept the doubled backslashes
  and the normalised path matched no protected pattern. The fallback now undoes the common JSON
  escapes (`\\`, `\"`, `\/`) in a single pass before comparing. It is still not a JSON parser and
  `init` step 7 says exactly what its limits are; installing `jq` remains what makes the hook
  reliable.
- A knowledge document whose `covers_paths` key is present but unreadable is now found on every
  run of `check-docs.sh`, not only on runs where some file changed: a discarded opt-in is a
  property of the document, not of the diff. Documents with no `covers_paths` key at all are named
  in one summary line per run instead of one line each, and the closing warning names what was
  actually found — drift, a broken opt-in, or both — instead of calling every finding drift.
- `check-docs.sh` no longer asserts "one branch and no remote" when the enumeration of branches or
  remotes itself failed; those runs get the generic no-base message, whose advice does not depend
  on repository shape.
- Both check scripts assumed they were run from the repository root and never verified it. A
  relative `DOCS_DIR` resolves against the working directory while `git diff --name-only` prints
  root-relative paths, so a run from any subdirectory found no documents, printed "no documents in
  docs/knowledge, nothing to check" and exited 0 — a full green from a repository with real drift,
  decided by where the operator was standing. Both scripts now resolve
  `git rev-parse --show-toplevel` and change to it before doing anything, and exit 2 with a message
  when run outside a git repository. This changes the meaning of a relative `DOCS_DIR` from
  "relative to the caller's working directory" to "relative to the repository root"; an absolute
  `DOCS_DIR` behaves as before.

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
- `check-docs.sh` distinguishes two reasons for having no base ref. A repository with one branch and
  no remote is told that no base can exist yet, that the check becomes meaningful once there is a
  trunk, and that the scaffold is not broken — instead of being told to pass the ref the work
  branched from, which does not exist there.
- `check-staleness.sh` states its exit-code contract in its header, in the same three-code form as
  `check-docs.sh`, and ends a healthy run with `N documents checked, none stale.` A run that printed
  nothing could not be told apart from a script that never ran.
- `audit` check 3 now runs `check-docs.sh` and states how to read each exit code, with exit 2 as a
  high-severity finding. The by-hand `covers_paths` test stays, and the file says why both exist.
  Check 7 covers routing-table rows pointing at a directory, not only at a file.
- `init` states the `jq` dependency of `protect-files.sh` in step 7, and says in step 6 that the
  repository's own tooling is deliberately outside the drift check. The generated
  `03-architecture.md` carries that scope sentence so the decision survives the conversation.

### Known defects

- `protect-files.sh` matches its protected patterns as unanchored substrings: nothing ties a
  pattern to a path boundary, so `vendor/x/docs/decisions/y.md` and `mydocs/decisions/y.md` are
  both treated as protected by the pattern `docs/decisions/`. The effect is over-blocking — an
  edit to an unrelated file whose path merely contains a protected string is refused, with a
  message about decision immutability that does not apply to it. Low severity: the error is in
  the safe direction and never allows a write it should block. Unfixed as of 2026-08-16.
- With an absolute `DOCS_DIR`, the "document was touched" suppression in `check-docs.sh` can never
  fire: the suppression compares `$doc` — absolute in that configuration — against the
  root-relative paths `git diff --name-only` prints, so the match always fails and a document that
  was updated alongside its code is still reported as drifting. Low severity: the error is a false
  positive, never a missed drift, and only in the non-default absolute-`DOCS_DIR` configuration.
  Unfixed as of 2026-08-16.

### Corrected

- **The 0.1.0 entry below claimed that `protect-files.sh`'s `sed` fallback, together with the
  backslash normalisation, made Windows paths match the protected patterns. Together those two
  clauses claim more than the released code did.** Each clause is individually true, but the
  normalisation only ever received a correctly unescaped path — which meant the `jq` branch. In
  the `sed` fallback a JSON-escaped Windows path kept its doubled backslashes, matched no
  protected pattern, and the write was allowed. That gap is what the `Fixed` entry above about
  the fallback's JSON unescape closes. The claim is marked in place in the 0.1.0 entry rather
  than deleted: released text is not quietly rewritten.
- **The 0.1.0 entry below claimed that `check-staleness.sh` gained a base-ref fallback chain. It
  never had one, in any version.** The script takes no argument, names no ref, and compares each
  document against its own `basis_commit`. The claim is marked in place in the 0.1.0 entry rather
  than deleted: released text is not quietly rewritten. The rest of that entry was re-read against
  the files it describes and nothing else in it was contradicted.

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
  **[Wrong, as written. Corrected under `0.2.0` → `Corrected`, 2026-08-16.]** The empty-docs
  half holds for both scripts. The base-ref half was only ever true of `check-docs.sh`:
  `check-staleness.sh` has never had a base ref of any kind. Its comparison point is each
  document's own `basis_commit`.
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
  **[Overstated, as written. Corrected under `0.2.0` → `Corrected`, 2026-08-16.]** The two
  sentences are individually true, but together they claim the fallback matched Windows paths. It
  did not: the normalisation only ever ran on a correctly unescaped path, which meant the `jq`
  branch, and in the `sed` fallback a JSON-escaped Windows path was not matched and the write was
  allowed.

[0.2.0]: https://github.com/octonify/claude-plugins/releases/tag/project-memory--v0.2.0
[0.1.0]: https://github.com/octonify/claude-plugins/releases/tag/project-memory--v0.1.0
