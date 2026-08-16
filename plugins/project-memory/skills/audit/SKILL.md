---
name: audit
description: Report on the health of a repository's project memory — CLAUDE.md and knowledge files over budget, missing or stale basis_commit headers, covers_paths pointing at paths that no longer exist, claims without confidence markers, commits not following Conventional Commits, and whether the commit hook and git notes refspec are actually configured. Use when asked to check, audit or review documentation health, staleness, drift, or whether the docs still match the code.
when_to_use: Requests like "audit the docs", "is our documentation stale", "check documentation health", "has CLAUDE.md drifted", "review our project memory", "are the doc hooks actually on".
argument-hint: "[optional: path to the repository]"
---

# Audit project memory

**Report only. Change nothing.** Do not edit files, do not create files, do not run `git config`,
do not stage or commit. Fixing is a separate instruction the user has to give afterwards. If a
finding has an obvious fix, name it in one line; do not apply it.

Work in the current directory unless the user named another. If the target has no `CLAUDE.md` and
no `docs/knowledge/`, say the structure is absent and suggest `/project-memory:init` instead of
producing an empty report.

## Checks

Run all of them. A check whose inputs are missing reports "not applicable", not silence.

### 1. Budgets

Count lines. Report anything over.

| File | Budget |
|---|---|
| `CLAUDE.md` | 200 |
| `docs/knowledge/*.md` | 150 |
| `docs/decisions/*.md` | 60 |
| `.claude/rules/*.md` | 100 |

Also count `@path` imports in `CLAUDE.md`: they load at launch alongside the parent, so their
lines count against the same context cost even though they are not in the same file.

### 2. Staleness headers

For every `docs/knowledge/*.md`, read the YAML frontmatter:

- `basis_commit` missing → report.
- `basis_commit` not resolvable (`git cat-file -e <sha>^{commit}`) → report as unknown.
- `git rev-list --count <basis>..HEAD` above 200 → report as stale, with the count.
- `review_trigger` missing, or phrased as a date or cadence rather than an event → report. "Wrong
  as soon as the deployment target changes" is a trigger; "reviewed quarterly" is not.
- `as_of` more than six months before today → report alongside the commit count, not instead
  of it.

`check-staleness.sh` covers the first three if it is installed — locate it the same way check 3a
locates the drift check, through the routing table. Run it and quote it rather than duplicating
its work.

### 3. The drift check, and `covers_paths` that point nowhere

Two questions, not one. Run the script for the first; do the second by hand. Both are needed, and
the reason is in the note at the end of this check — read it before deciding they are duplicates.

**3a. Locate the drift check through `CLAUDE.md`'s routing table, run it, and interpret what it
returns.** The routing table is the manifest: the row whose target names `check-docs.sh` says
where this repository keeps its drift check. Do not hardcode a location — the path has moved once
already, and a check that quietly stops checking because a path moved underneath it is the defect
class this skill exists to catch. Same rule as check 2: run it and quote it rather than
duplicating its work.

Resolve the location before the exit-code table applies:

- The table names a path and a script is there → run it.
- **The table names a path and nothing is there → high-severity finding, not "not applicable".**
  The memory promises a drift check that does not exist; every run since its deletion has checked
  nothing while the table said otherwise.
- The table names no drift check at all → look in `.githooks/check-docs.sh` and
  `scripts/check-docs.sh` before concluding anything; scaffolds made before the tooling rows
  existed installed the script without a row. A script found there is run as normal, plus a
  low-severity finding that the routing table does not name it. Nothing in the table and nothing
  at either location → not applicable, per the rule at the top of this section.

| Exit | What to report |
|---|---|
| 2 | **high severity, with one downgrade.** The drift check could not run at all — the script names the reason on stderr (not inside a git repository, no usable base ref, no common ancestor, or a failed diff); quote that reason and any base refs it rejected. A repository whose drift check has never run is a repository whose knowledge files have never been checked against the code, however green the last run looked. **Downgrade to low — never suppress — when the script's own stderr says the repository has one branch and no remote**, so no base ref can exist yet. High means "wrong or silently unenforced", and nothing there is silent: the script said out loud that it compared nothing, and a repository that cannot yet have a base has nothing to drift against. The finding still appears and still says the drift check has never compared anything; only the severity changes, and only in the state the script itself identifies. Any other exit-2 reason stays high. |
| 1 | drift found, and `STRICT=1` was set. Quote the `DRIFT:` lines. |
| 0 | it ran against a base it named. Quote the base ref, and quote any `DRIFT:` lines or skipped-document lines it printed — exit 0 with warnings is the default configuration, so 0 does not mean "no findings". |
| never ran | resolved by the location rules above, before this table — a named path with nothing at it is a finding, and only a repository whose table names no tooling and has none installed is "not applicable". |

The script also names every knowledge document it did not check. A document with no `covers_paths`
key is an opt-out and only worth noting; a document whose key is present but could not be read is a
broken opt-in — report that one, it was asking to be checked and was not.

**3b. `covers_paths` entries that point nowhere.** For each entry, strip the glob to its literal
prefix and test whether anything in the repository matches it, **anchored at the start of the
path and with a literal `.` treated as a literal `.`** — the same rules `check-docs.sh` applies,
so the two never answer the same question differently. `src/api/**` is not matched by
`vendor/foo/src/api/x.ts`, and `src/v1.2/` is not matched by `src/v1x2/`. Report every entry with
no match — that document's drift check has been passing vacuously.

Then report the inverse: top-level source directories that no knowledge file covers at all. Tooling
directories are excluded from that inverse by design; see the note on drift-check scope in the
generated `docs/knowledge/03-architecture.md`.

**Why both.** `check-docs.sh` answers "did covered code change without its document changing", over
one diff range. 3b answers "is this entry pointing at anything at all", over the whole tree. An
entry that points nowhere makes the script pass *vacuously* — the script cannot detect it, because
from inside a diff a pattern that matches nothing is indistinguishable from a pattern whose paths
did not change. Deleting 3b as duplication removes the only check on the check.

### 4. Unsourced claims

Scan `docs/knowledge/*.md` bodies for declarative claims with no `[F]`/`[I]`/`[U]` marker. Report
counts per file plus up to five examples. Skip headings, table header rows, code blocks, and
template placeholder lines.

A `[F]` with no source path or no date is a finding of the same kind: it asserts provenance it
does not carry.

### 5. Commit message discipline

```bash
git log -n 50 --pretty=format:%s
```

Report the share not matching
`^(feat|fix|docs|refactor|perf|test|build|ci|chore|style|revert)(\(...\))?!?: .+`, ignoring
`Merge`, `Revert`, `fixup!` and `squash!` subjects. Quote up to five offenders.

Then count decision trailers over the same window:

```bash
git log -n 50 --grep='^Decision:' --pretty=format:'%h %s'
```

Zero trailers with many non-trivial commits means Part 3 of the structure is decorative — history
is being written in a form nothing can query later.

### 6. Enforcement actually configured

Each of these is a yes/no. Report the value found, not just the verdict.

- `git config core.hooksPath` → is it set, and does the file it points at exist and contain a
  `commit-msg` hook?
- Is `.githooks/commit-msg` executable? On a fresh clone, a non-executable hook silently never
  runs. Check the index bit: `git ls-files -s .githooks/commit-msg` should start `100755`.
- `git config --get-all remote.origin.fetch` → does any entry contain `refs/notes/*`? If not,
  notes are not being fetched and nothing will signal their absence.
- Do any notes exist locally (`git notes list`)? Local notes plus a missing refspec is the
  specific case where knowledge is already at risk.
- `.claude/settings.json` → are the `PreToolUse` and `SessionStart` hooks present, and do the
  scripts they name exist and run?

### 7. Filename honesty

Sample each `docs/knowledge/*.md` and check its content matches its name. Operations content in
`03-architecture.md` breaks the routing table silently: the agent opens the right file, does not
find the answer, and guesses. Report any file whose content has drifted away from its filename.

Also report routing-table rows in `CLAUDE.md` whose target does not exist — a file, or a directory,
or a directory that exists but is empty. A row pointing at an empty `docs/decisions/` routes the
agent to nothing just as effectively as one naming a missing file.

### 8. Decision record integrity

- Any `docs/decisions/*.md` with status `accepted` modified after the commit that added it →
  report; accepted records are immutable. One exception: a modification is not a finding when
  every added line falls under a trailing `## Notes` heading and no line was removed. Check it
  mechanically, not by judgement: find the adding commit with
  `git log --diff-filter=A --format=%H -- <file>`, then read
  `git diff <adding-commit>..HEAD -- <file>`. The exception holds only if the diff has no `-`
  lines (the `---` file header aside) and every `+` line is at or below a `+## Notes` line or a
  `## Notes` context line that is the file's last section. A removed line, a changed line above
  `## Notes`, or an added heading after `## Notes` is a finding as before.
- Numbering gaps or duplicates.
- Any ADR whose Context section is one line — the Context paragraphs are the only reason the file
  exists rather than a commit trailer.

## Output

One table, most severe first:

| Severity | Check | Finding | Suggested fix (not applied) |
|---|---|---|---|

Severity: **high** = the memory is wrong or silently unenforced; **medium** = it will be wrong
soon; **low** = hygiene.

Then a one-paragraph verdict answering: would a new person, cloning this repository alone, be able
to work in it?

## The five-minute recovery test

End every report with this, phrased for the user to run themselves:

> Clone this repository into a clean directory, open an agent session there, and ask three
> questions. Nothing outside the clone may be consulted.
>
> 1. What is this project and what is its current state?
> 2. Why was <name one non-obvious choice in this repository> made this way?
> 3. What do we not know yet?
>
> An answer to all three from the clone alone means the memory is durable. Anything you had to
> supply from your own head, your own machine, or a chat log is the gap.

Fill in question 2 with an actual non-obvious choice found during the audit, not a placeholder.

## Adapting the checks

`reference/architecture.md` in this plugin gives the reasoning behind the budgets, the confidence
markers and the git-versus-markdown split. Read it only when a finding has to be justified to a
user who disagrees with the rule behind it, or when the repository's shape means a check should be
waived rather than reported.
