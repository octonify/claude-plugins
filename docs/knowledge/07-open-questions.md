---
as_of: 2026-08-16
basis_commit: a9afd9e
owner: octonify
review_trigger: any source contradiction, or a needed fact with no source
---

# Open questions

The negative space of this repository. Not a to-do list: an open question is something not known,
not something not yet done. Items leave this file with evidence or with an explicit decision to stop
asking.

This is the only file of the `project-memory` structure that this repository has adopted so far. The
rest waits until the plugin's own layout stops moving; see item 8.

| # | Question | Why it matters | Blocked on | Raised | Status |
|---|---|---|---|---|---|
| 1 | Does a fresh install read plugin content from the marketplace repository's default branch, so that pushing unbumped changes ships them to new installers under the old version string? | Governs the release policy of every round. `version` pins updates for installed users and determines cache paths; what a *new* installer receives is the open half. | Confirmed [F] against the official docs for the first two points; the third — two installs reporting `0.1.0` with different files — has not been observed on a clean machine. | 2026-08-16 | open |
| 2 | Is there a systematic way to find silent-failure sites, rather than a careful reread each round? | Round 1 found six by reading every shipped file and still missed the `git diff` swallow one line below the guard it added. A third round of rereading will miss something too. | A candidate exists — grep for the syntactic forms `\|\| true`, `\|\| echo`, `2>/dev/null` and `[ -z ... ] && continue`, and require each surviving one to carry a comment saying why silence is right — but it has not been run as a gate. | 2026-08-16 | open |
| 3 | Does rejecting a *tautological explicit* base ref match what the planning layer wants, or should an explicit base mean "I know what I am doing, do it anyway"? | It is the difference between the round-1 green being closed and being one flag away from returning. | A decision. It is a one-line downgrade to a warning. | 2026-08-16 | open |
| 4 | Did removing the empty-tree fallback break a case someone depends on? | 0.1.0 shipped; who is running it, and how, is not known. | Evidence from a real installation. | 2026-08-16 | open |
| 5 | How much of the 0.1.0 `CHANGELOG.md` came from the same pass that produced the `check-staleness.sh` base-ref claim, which was never true? | A wrong changelog is a wrong source for every later round. One claim is now corrected; the entry was re-read against the files and nothing else contradicted them, but absence of contradiction is not provenance. | Nothing further available from inside the repository. | 2026-08-16 | open |
| 6 | Is `docs/decisions/` protected by `protect-files.sh` in a repository where `init` never creates it? | A hook that guards a path that does not exist never fires and never says so. This is defect 2 and is out of scope until it is scheduled. | The defect 2 round. | 2026-08-16 | open |
| 7 | Without `jq`, `protect-files.sh` reads a JSON-escaped Windows path as `D://Projects//...` and allows a write to a protected file. Does the `sed` fallback need to unescape, or does the plugin declare `jq` a hard dependency? | The fallback exists so a missing `jq` degrades to "allow" rather than blocking every edit — but here it allows a write it was installed to block, silently, with a path it believes it read correctly. | A decision on which of the two. Reproduced 2026-08-16; the `jq` path blocks the same input correctly. | 2026-08-16 | open |
| 8 | When does this repository adopt the structure its own plugin scaffolds? | A marketplace shipping `project-memory` without `CLAUDE.md` frontmatter, knowledge files or the hooks is its own finding. | The layout settling — defect 5 moves `scripts/` into `.githooks/`. Adopting first would mean migrating twice. | 2026-08-16 | open |

## Rules

- A contradiction between two sources is an open question, not a fact to be chosen between.
- "Nobody knows" and "it was never recorded" are valid resolutions, written down as such with the
  date they were established.
- Nothing leaves this file without either evidence or an explicit decision to stop asking.
