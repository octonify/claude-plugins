---
name: init
description: Scaffold a git-native long-term project memory structure in the current repository — CLAUDE.md with a routing table, docs/knowledge arc42 files, docs/decisions ADRs, a Conventional Commits commit-msg hook, and drift/staleness checks. Use when asked to set up project memory, agent memory, documentation structure, a CLAUDE.md, an ADR log, or knowledge management for a repository.
when_to_use: Requests like "set up project memory here", "create a CLAUDE.md", "add ADRs", "scaffold docs structure", "set up documentation for agents", "add a commit message hook", "make this repo agent-readable".
argument-hint: "[optional: path to the repository]"
---

# Initialise project memory

Scaffold the minimum viable memory structure in the target repository. Assets referenced below
live at `${CLAUDE_PLUGIN_ROOT}/assets/`. Copy them; do not re-derive their contents.

The single biggest failure mode is creating all nine knowledge files. Nine empty files read as
nine assignments and the corpus fills with restated code. Create four files — three knowledge
files and one decision record. Offer the rest.

## Step 1 — Survey the target repository

Work in the current directory unless the user named another. Confirm it is a git repository; if
not, stop and ask.

Record what already exists, and read anything that does:

- `CLAUDE.md`, `AGENTS.md`, `CLAUDE.local.md`
- `docs/`, in particular `docs/knowledge/` and `docs/decisions/`
- `.claude/settings.json`, `.claude/hooks/`, `.claude/rules/`
- `.githooks/`, and `git config core.hooksPath`
- `scripts/check-docs.sh`, `scripts/check-staleness.sh`

**Never overwrite an existing file.** For each collision, ask: merge, write alongside as
`<name>.new`, or skip. Default to skip if the user does not answer.

## Step 2 — Learn the project well enough to write about it

Do not emit a file full of placeholders. Before writing `CLAUDE.md`, establish:

- What the project is, for whom, and its lifecycle stage — from the README, package manifest, or
  the code itself.
- The **real** build, test and lint commands. Read `package.json` scripts, `Makefile`, `justfile`,
  `pyproject.toml`, `Cargo.toml`, `go.mod`, CI workflow files. If a command genuinely cannot be
  determined, write `unknown` and add the gap to `07-open-questions.md`; never invent one.
- Two or three things that look reasonable but are wrong in this repository, for the `Do not`
  section. If nothing is known yet, leave the section with a single line saying so.

Note the current commit: `git rev-parse --short HEAD`. Note today's date.

## Step 3 — Create exactly four files

| File | From |
|---|---|
| `CLAUDE.md` | `assets/CLAUDE.md.template` |
| `docs/knowledge/03-architecture.md` | `assets/architecture.md.template` |
| `docs/knowledge/07-open-questions.md` | `assets/open-questions.md.template` |
| `docs/decisions/0001-<slug>.md` | `assets/adr-template.md` |

Fill every `{{PLACEHOLDER}}` with real content or delete the line. Substitute the date and short
commit into `as_of` and `basis_commit`. Set `covers_paths` to globs that actually exist in the
repository; an entry pointing nowhere makes the drift check silently useless.

Keep `CLAUDE.md` under 200 lines. Generate its routing table from the file set this run actually
created: a row exists because its target was written in this step, not because the template
carried it. Do not copy the template's table and trim it afterwards.

**ADR 0001 is the target project's decision to adopt this structure**, written from what step 2
learned about that repository. It is not a description of this plugin: a record that would read
identically in every repository is filler, the exact failure mode named at the top of this file.

- **Context** — paragraphs, not one line: what the project is, what state its documentation was
  in before this run, and why a durable memory layer is worth the files it costs *here*. `audit`
  check 8 reports a one-line Context as a finding, and a scaffold that fails its own audit on
  creation is defective. If step 2 could not learn enough to write real Context, say so and
  write the gap into `07-open-questions.md` instead of inventing a rationale — the same rule as
  the build commands.
- **Decision** — adopting the structure, naming which parts were installed and which declined.
- **Consequences** — what now has to be maintained, and what the routing table now promises. At
  least one consequence must name something that is true only in this repository; a Consequences
  section that would survive transplantation into another project unedited is the generic list
  this spec exists to prevent.
- Under 60 lines: `audit` check 1's budget. Nygard format, from the template: title,
  `**Status:** accepted`, `**Date:**`, Context, Decision, Consequences.
- Filename in the target repository's own voice, in the shape of
  `docs/decisions/0001-adopt-a-git-native-project-memory-structure.md`.

Why this file is created rather than offered — recorded here so a later change does not move it
into step 4's list: four shipped artifacts already route an agent to `docs/decisions/` — the
`CLAUDE.md` routing table, `03-architecture.md` §9, `protect-files.sh`'s `PROTECTED` list, and
this skill's own `description`. A promise with nothing behind it is worse than a fourth file,
because the routing table's whole purpose is to stop an agent guessing, and a row pointing at an
empty directory makes it guess with confidence.

## Step 4 — Offer, do not create, the rest

List these and create only the ones the user asks for:

`00-index.md`, `01-identity.md`, `02-sources.md` (template available), `04-inventory.md`,
`05-operations.md`, `06-people.md`, `08-glossary.md`.

The rule to state when offering: each file is created the day it has real content, and a file
that restates what the code says is a net loss because it competes for retrieval.

One more offer, of a different kind. If step 1's survey turned up a choice in this repository
that is non-obvious and undocumented — an unusual dependency, a structure that contradicts its
framework's default, a workaround with no comment — offer to record it as ADR 0002. The offer
names the choice and asks the user why it was made; the answer is what makes the record worth
having. Never write it unasked, and never guess the reason. If the user does not answer, write
nothing and put the question into `07-open-questions.md`, which is where an unanswered why
belongs. One offer at most: a skill that offers five is a skill that gets its offers dismissed.

## Step 5 — Install the commit-msg hook

```bash
mkdir -p .githooks
cp "${CLAUDE_PLUGIN_ROOT}/assets/commit-msg" .githooks/commit-msg
chmod +x .githooks/commit-msg
git add --chmod=+x .githooks/commit-msg
git config core.hooksPath .githooks
```

`git add --chmod=+x` is not redundant. On Windows `chmod` does not reach git's index, so the hook
is committed as `100644` and is not executable in any fresh clone on Linux or macOS — where it
then silently never runs. Verify with `git ls-files -s .githooks/commit-msg`; it must start
`100755`.

`core.hooksPath` is per-clone **local** config. It is not committed and it does not travel with a
clone: everyone else gets the hook file and no hook execution, with no warning of any kind. Two
consequences, both required:

- The generated `CLAUDE.md` carries the setup line — `git config core.hooksPath .githooks` under
  `## Commands`. Keep it. It is one line and it is the only thing a new clone has to be told.
- Step 9's report says so explicitly, in the wording given there.

If `core.hooksPath` is already set to something else, do not change it — report the conflict and
stop at copying the file in.

## Step 6 — Install the checks as warnings

```bash
mkdir -p scripts
cp "${CLAUDE_PLUGIN_ROOT}/assets/check-docs.sh" scripts/
cp "${CLAUDE_PLUGIN_ROOT}/assets/check-staleness.sh" scripts/
chmod +x scripts/check-docs.sh scripts/check-staleness.sh
git add --chmod=+x scripts/check-docs.sh scripts/check-staleness.sh
```

Same reason as step 5: the index bit is what survives a clone, and `chmod` alone does not set it
on Windows.

Then make sure the target repository pins line endings for these files, appending to
`.gitattributes` if it exists and creating it if it does not:

```
*.sh        text eol=lf
.githooks/* text eol=lf
```

A hook or script checked out with CRLF fails on Linux and macOS with
`bad interpreter: /usr/bin/env bash^M`.

The drift check covers the code the knowledge files describe. The repository's own tooling — the
hooks, the checks, the agent configuration — is deliberately outside it, and the generated
`03-architecture.md` carries that sentence so the decision survives this conversation. Say it once
here too: deleting `check-docs.sh` will not make any check fail, by design, because a knowledge
file whose job is to describe the checks costs more structure than it earns.

Both scripts exit 0 on findings by default and only fail when `STRICT=1` is set. Leave it that
way. Do not add them to CI as blocking, and do not set `STRICT=1` on this run. Say explicitly
that promotion to blocking is a later, separate decision, once the output is quiet.

Run both once and show the output. **`check-docs.sh` exits 2 when it cannot determine a base ref**
— on a repository whose only branch is the one checked out, which is the usual state of a freshly
scaffolded project, that is the expected first run. It is not a failure of the scaffold: the check
is refusing to report success without having compared anything. Say that when it happens, and name
the explicit-base form, `./scripts/check-docs.sh <ref>`, for the first branch the user cuts.

Exit codes for `check-docs.sh`: 0 ran against a named base, 1 drift found under `STRICT=1`, 2 could
not run — not inside a git repository, or no usable base. 2 is independent of `STRICT`, because an
inability to run is not a finding.

Both scripts change to the repository root before doing anything, so they can be run from any
directory inside the repository. A relative `DOCS_DIR` is therefore relative to the repository
root, not to the caller's working directory; an absolute `DOCS_DIR` is used as-is. That is the
correct semantic for a repository-level check, and it means the operator's location can never turn
a run with findings into a green one.

`check-staleness.sh` uses the same three codes: 0 ran, 1 findings under `STRICT=1`, 2 could not run
at all — no `HEAD` to count against. A single document whose commit count cannot be taken is
reported as a finding against that document, not as a failure of the whole run, because its
comparison point is its own `basis_commit` rather than one shared base.

## Step 7 — Offer the agent hooks

Only if the user wants enforcement beyond the commit hook:

```bash
mkdir -p .claude/hooks
cp "${CLAUDE_PLUGIN_ROOT}/assets/protect-files.sh" .claude/hooks/
chmod +x .claude/hooks/protect-files.sh
git add --chmod=+x .claude/hooks/protect-files.sh
```

Merge `assets/settings.json.fragment` into `.claude/settings.json`. If that file already exists,
merge by hand into the existing `hooks` object; never replace the file. Tell the user to edit the
`PROTECTED` array in `protect-files.sh` to match the project.

State the dependency at this point, in the report, so the choice is made knowingly now rather than
discovered when a write goes through: **`protect-files.sh` reads its input with `jq` and falls back
to a `sed` extraction when `jq` is not installed.** Check with `command -v jq` and say which of the
two this machine will use. The fallback is deliberate — a protection hook that cannot read its
input allows the write rather than blocking every edit — and when it cannot find a path at all the
hook says so on stderr and still allows. The fallback's escape handling is limited: it undoes the
common JSON escapes (`\\`, `\"`, `\/`) so Windows paths compare correctly, but it is not a JSON
parser — `\n`, `\uXXXX` or quotes inside a path still defeat it, and a write it cannot parse is an
unenforced write. Installing `jq` is what makes the hook reliable rather than best-effort.

## Step 8 — Offer git notes transfer

Notes are not pushed or fetched by default and nothing signals their absence:

```bash
git config --add remote.origin.fetch '+refs/notes/*:refs/notes/*'
```

Only run this if a remote named `origin` exists and the user agrees.

## Step 9 — Report

Print these five blocks, in this order:

1. **Created** — every path written.
2. **Skipped** — every path not written, with the reason (existed / declined / not applicable).
3. **The hook is active in this clone only.** Not a footnote; its own block, before `Next`. State
   all three parts:

   > The `commit-msg` hook is active in **this clone only**. `core.hooksPath` is local git config:
   > it is not committed and it does not travel. Every other clone — every teammate, every CI
   > checkout, every fresh clone of your own — gets the hook file and no hook execution, silently.
   > Each one needs this once: `git config core.hooksPath .githooks`
   > The line is written down in `CLAUDE.md` under `## Commands`, so a new clone can find it
   > without being told.

   A local hook is fast feedback, not enforcement. It is also skippable with `--no-verify`. If the
   commit format has to hold for everyone, that check belongs in CI, where it runs on the server
   rather than on whoever remembered to configure their clone.

4. **The `Decision:` trailer for the commit the user is about to make.** `init` does not commit,
   so it cannot write the trailer itself; it hands the text over, ready to paste. One block,
   naming every adaptation this run actually made to a shipped default — a trimmed `PROTECTED`
   array, a declined component, a section dropped from a template — in the trailer format
   `reference/architecture.md` §5 documents:

   ```
   Decision: <the adaptations made, and why they fit this repository>
   Rejected: <the shipped default, or the alternative not taken>
   ```

   Adaptations of this size are trailer material, not ADR material — cheap and local to reverse.
   Do not fold them into ADR 0001. If this run made no adaptations, say so instead of emitting an
   empty template.

5. **Next** — two or three concrete actions. Pick from: fill `07-open-questions.md` with what is
   currently unclear (usually the highest-value next hour); make one real commit to confirm the
   hook fires; add `covers_paths` globs once `03-architecture.md` has real content; run
   `/project-memory:audit` in a week.

Do not commit anything. Leave the changes staged or unstaged as they are and let the user commit.

## When the target repository does not fit the defaults

`reference/architecture.md` in this plugin explains the reasoning behind the file split, the
budgets, the confidence markers, and the git-versus-markdown allocation. Read it only when a
choice here has to be adapted or defended — for example a monorepo needing per-package knowledge
files, a project already using `AGENTS.md`, or a user who wants the drift check blocking on day
one.
