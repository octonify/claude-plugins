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

`scripts/check-staleness.sh` covers the first three if it is installed. Run it and quote it rather
than duplicating its work.

### 3. `covers_paths` that point nowhere

For each entry, strip the glob to its literal prefix and test whether anything in the repository
matches. Report every entry with no match — that document's drift check has been passing
vacuously.

Then report the inverse: top-level source directories that no knowledge file covers at all.

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

Also report routing-table rows in `CLAUDE.md` pointing at files that do not exist.

### 8. Decision record integrity

- Any `docs/decisions/*.md` with status `accepted` modified after the commit that added it →
  report; accepted records are immutable.
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
