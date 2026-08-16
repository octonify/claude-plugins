---
as_of: 2026-08-16
basis_commit: b953d0c
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
| 1 | Does a fresh install read plugin content from the marketplace repository's default branch, so that pushing unbumped changes ships them to new installers under the old version string? | Governs the release policy of every round. `version` pins updates for installed users and determines cache paths; what a *new* installer receives is the open half. | Confirmed [F] against the official docs for the first two points; the third — two installs reporting `0.1.0` with different files — has not been observed on a clean machine. | 2026-08-16 | open; narrowed 2026-08-16: the update half is now observed [F] — after the 0.2.0 release, an existing installation moved 0.1.0 → 0.2.0 via `claude plugin update` (marketplace update alone did not move it), and the cached copy was content-identical to the tagged tree. The fresh-install-on-a-clean-machine half remains unobserved and keeps the item open. |
| 2 | Is there a systematic way to find silent-failure sites, rather than a careful reread each round? | Round 1 found six by reading every shipped file and still missed the `git diff` swallow one line below the guard it added. A third round of rereading will miss something too. | A candidate exists — grep for the syntactic forms `\|\| true`, `\|\| echo`, `2>/dev/null` and `[ -z ... ] && continue`, and require each surviving one to carry a comment saying why silence is right — but it has not been run as a gate. | 2026-08-16 | resolved 2026-08-16: the grep is CLAUDE.md hard rule 10 and had its first run in the round-3 report; it found five deliberate-but-uncommented sites, so round 2's belief that every surviving site was deliberate held, and its belief that they were all annotated did not. |
| 3 | Does rejecting a *tautological explicit* base ref match what the planning layer wants, or should an explicit base mean "I know what I am doing, do it anyway"? | It is the difference between the round-1 green being closed and being one flag away from returning. | A decision. It is a one-line downgrade to a warning. | 2026-08-16 | open |
| 4 | Did removing the empty-tree fallback break a case someone depends on? | 0.1.0 shipped; who is running it, and how, is not known. | Evidence from a real installation. | 2026-08-16 | open |
| 5 | How much of the 0.1.0 `CHANGELOG.md` came from the same pass that produced the `check-staleness.sh` base-ref claim, which was never true? | A wrong changelog is a wrong source for every later round. One claim is now corrected; the entry was re-read against the files and nothing else contradicted them, but absence of contradiction is not provenance. | Nothing further available from inside the repository. | 2026-08-16 | open |
| 6 | Is `docs/decisions/` protected by `protect-files.sh` in a repository where `init` never creates it? | A hook that guards a path that does not exist never fires and never says so. This is defect 2 and is out of scope until it is scheduled. | The defect 2 round. | 2026-08-16 | resolved 2026-08-16: the defect 2 round (round 7) makes `init` create `docs/decisions/` with a first record, so in every new scaffold the guarded path exists; verified by a blocked write, exit 2, against the created ADR. Repositories scaffolded by 0.1.0/0.2.0 keep the old shape — there the hook still guards a path that may not exist, and nothing says so. |
| 7 | Without `jq`, `protect-files.sh` reads a JSON-escaped Windows path as `D://Projects//...` and allows a write to a protected file. Does the `sed` fallback need to unescape, or does the plugin declare `jq` a hard dependency? | The fallback exists so a missing `jq` degrades to "allow" rather than blocking every edit — but here it allows a write it was installed to block, silently, with a path it believes it read correctly. | A decision on which of the two. Reproduced 2026-08-16; the `jq` path blocks the same input correctly. | 2026-08-16 | resolved 2026-08-16: the fallback unescapes `\\`, `\"` and `\/` in one pass (round 3, defect 10). `jq` stays optional and is named in `init` step 7 as what makes the hook reliable; the fallback remains best-effort and says so. |
| 8 | When does this repository adopt the structure its own plugin scaffolds? | A marketplace shipping `project-memory` without `CLAUDE.md` frontmatter, knowledge files or the hooks is its own finding. | A decision by the planning layer. The stated blocker — the layout settling — cleared 2026-08-16 when the round-8 move put the checks in `.githooks/` and split the methodology into `.claude/rules/`; adopting now means adopting the settled shape. | 2026-08-16 | open |
| 9 | Do the shipped scripts behave on non-Windows platforms as the Windows transcripts say? | The scripts run on whichever machine installs the plugin; until 2026-08-16 every transcript came from one Windows machine. | The macOS half. BSD `sed`, `grep` and `awk` differ from GNU, and two lines depend on BRE portability — `escape_bre()` and the fallback unescape in `protect-files.sh`. Both are portable by construction, which is [I], not an observation. | 2026-08-16 | open; narrowed 2026-08-16: the Linux half is [F] — the planning layer ran all four shipped scripts of 0.2.0 in its Linux container (GNU bash 5.2.21, git 2.43.0, GNU sed 4.9, `jq` present and shadowed), thirteen cases plus detached HEAD, a repository path with a space, and locales `C`/`POSIX`/`en_US.UTF-8`; every verdict, exit code and message matched the Windows transcripts. The scripts run were reconstructed from round attachments, since verified byte-identical to the `project-memory--v0.2.0` tag [F]. The one macOS risk checkable from Linux — BSD-style `wc -l` padding on the branch count — is ruled out: bash tolerates leading whitespace in integer comparison [F]. macOS itself remains unobserved and keeps the item open. |

## Rules

- A contradiction between two sources is an open question, not a fact to be chosen between.
- "Nobody knows" and "it was never recorded" are valid resolutions, written down as such with the
  date they were established.
- Nothing leaves this file without either evidence or an explicit decision to stop asking.
