# Long-Term Project Memory: a local, git-native structure

A general template for keeping durable project memory on your own machine, for any software
project worked on with AI agents.

**Template version:** 3.0 · **Date:** 2026-08-15

**Read this once, then keep it as a reference.** It is deliberately long. It is not a file that
gets loaded into an agent's context; the file that does is `CLAUDE.md`, and Part 2 caps it at
200 lines.

**Changes from 2.0:** added Part 3 (git as the history layer) and Part 5 (local durability:
what survives and what silently does not).

---

# Part 0 — The one-page answer

Project memory is not one thing. It is four, and each has a different natural home. Putting them
all in markdown files is the mistake that makes documentation feel like a tax.

| Memory | Question it answers | Home | Why there |
|---|---|---|---|
| **Instructions** | how do we work here | `CLAUDE.md`, `.claude/rules/` | must be loaded every session |
| **Knowledge** | what is true now | `docs/knowledge/*.md` | must be readable in one pass |
| **History** | what changed and why | **git commits, trailers, notes, tags** | already an event log, free |
| **Decisions** | why the system is shaped this way | `docs/decisions/*.md` | the value is in the context paragraphs |

The organising principle: **git is an excellent event log and a terrible current-state
document.** To learn "what is true now" from git you must replay history. To learn "what changed
and why" from a markdown file you must hand-maintain a changelog, which drifts. Each covers the
other's weakness exactly. Use both, for what each is good at.

The failure this avoids: a single long memory file that is too long to load every session, too
summarised to serve as a reference, and internally at war over whether superseded content is
overwritten or preserved.

---

# Part 1 — Structure

## Why the instruction file must stay small

An always-loaded instruction file is paid for on every session, and its length trades directly
against how reliably the agent follows it. Claude Code's documentation states the target
explicitly: keep `CLAUDE.md` **under 200 lines**, because longer files consume more context and
reduce adherence. It also notes that `@path` imports load at launch alongside the parent file,
so splitting by import organises content but does not reduce the context cost. Only path-scoped
rules and on-demand skills actually reduce it.

## Layout

```
project-root/
├── CLAUDE.md                     ← < 200 lines. Instructions + routing table. Always loaded.
├── AGENTS.md                     ← optional. If present, CLAUDE.md is `@AGENTS.md` + extras.
├── .githooks/
│   └── commit-msg                ← versioned git hooks. See Part 4.
├── .claude/
│   ├── settings.json             ← agent hooks. The enforcement layer. See Part 4.
│   ├── hooks/*.sh
│   └── rules/*.md                ← path-scoped via `paths:` frontmatter, loads on demand
├── scripts/
│   ├── check-docs.sh             ← drift check
│   └── check-staleness.sh
└── docs/
    ├── knowledge/
    │   ├── 00-index.md           ← the map: what lives where, and what state each file is in
    │   ├── 01-identity.md        ← what this is, what it is called, who owns it
    │   ├── 02-sources.md         ← provenance register: every source and its date
    │   ├── 03-architecture.md    ← arc42-shaped
    │   ├── 04-inventory.md       ← components, modules, services, one row each
    │   ├── 05-operations.md      ← environments, deployment, live usage, dependencies
    │   ├── 06-people.md          ← who knows what, who decides what
    │   ├── 07-open-questions.md  ← the negative space. First-class, not an appendix.
    │   └── 08-glossary.md        ← project-specific vocabulary
    └── decisions/
        └── NNNN-<slug>.md        ← one ADR per architectural decision, immutable once accepted
```

**Do not create this whole tree on day one.** See Part 2, Guard 1.

## Cross-cutting conventions

**1. Confidence markers on every non-obvious claim.**

| Marker | Meaning |
|---|---|
| `[F]` | Fact, stated directly in a named source |
| `[I]` | Inference, drawn from sources but not stated in them |
| `[U]` | Unverified. No source access, or the source is incomplete |

**2. Every claim carries a source and a date.**

```
[F, src/config/loader.ts:88, 2026-01-14]
```

A claim with no source is an inference and must be marked as one. This single rule is what stops
a knowledge base drifting into fiction.

**3. Every knowledge file carries a machine-readable staleness header.**

```yaml
---
as_of: 2026-01-14
basis_commit: a1b2c3d
owner: <name>
review_trigger: <the event that makes this file wrong>
covers_paths:
  - src/api/**
---
```

The trigger matters more than a date. "Reviewed quarterly" decays silently. "Wrong as soon as
the deployment target changes" does not. `covers_paths` is what the drift check in Part 4 reads.

**4. Current state and history are separated by file, not by section.** Knowledge files hold
what is true now and are overwritten in place. History lives in git. A changelog section inside
a current-state document is a contradiction and will surface as one.

**5. Do not document what an agent can derive.** Directory listings, dependency lists and
generated inventories go stale and cost context for nothing. Document pitfalls, rationale,
non-obvious constraints, and conventions that differ from the tool's defaults. This is the
single most effective anti-drift measure in the template: what you never wrote cannot go stale.

**6. Contradictions are recorded, not resolved by preference.** When two sources disagree, the
disagreement is the finding. It goes to `07-open-questions.md` until evidence settles it.
Choosing the more plausible one and moving on is how a corpus acquires confident errors.

**7. Filenames must be honest.** If `03-architecture.md` contains operations content, the routing
table in `CLAUDE.md` breaks *silently*: the agent opens the right file, does not find the answer,
and guesses instead of reporting. This is the worst failure mode in the structure because it
emits no signal. Content that does not match its filename is moved, not appended to.

---

# Part 2 — Guards against over-documentation

A template is a schema, and agents fill schemas. Nine empty files read as nine assignments. Left
alone, the predictable result is decision records for trivial choices, an open-questions file
that becomes a to-do list, and pages restating what the code already says.

The real cost is not disk. It is retrieval: the larger the corpus, the higher the chance the
agent reads the wrong document or a stale one. Documentation has a negative-return region and it
is easy to reach.

**Corroboration from the tooling.** Claude Code's `/doctor` proposes trims for a checked-in
`CLAUDE.md` by cutting content the model can derive from the codebase, specifically directory
layouts, dependency lists and architecture overviews, and keeping pitfalls, rationale and
conventions that differ from tool defaults. The tool authors draw the same line.

**Guard 1 — Start with three files, not nine.**

```
CLAUDE.md
docs/knowledge/03-architecture.md
docs/knowledge/07-open-questions.md
```

Every other file is created the day it has real content.

**Guard 2 — Numeric budgets, not adjectives.** An agent respects "max 150 lines". It does not
respect "be concise". Put these in `CLAUDE.md` as hard rules.

| File | Budget |
|---|---|
| `CLAUDE.md` | 200 lines |
| any `docs/knowledge/*.md` | 150 lines |
| any ADR | 60 lines |
| `.claude/rules/*.md` | 100 lines |

Over budget means split by topic or delete. Never shrink the font.

**Guard 3 — Documentation is event-driven, not schema-driven.** Each artifact has exactly one
trigger. No trigger, no document.

| Write this | Only when |
|---|---|
| a commit trailer | any non-obvious implementation choice, recorded where it happened |
| an ADR file | the decision is architectural, expensive to reverse, and needs paragraphs of context |
| an open question | two sources disagree, or a needed fact has no source at all |
| a knowledge file edit | something true yesterday is false today |
| a rule in `CLAUDE.md` | the agent got it wrong once, or a review caught something it should have known |
| a `.claude/rules/` file | the instruction applies to a subset of paths, not the whole repo |

**Guard 4 — Review the rule set for contradictions.** Claude Code's documentation warns that
when two rules contradict each other the model may pick one arbitrarily. Splitting rules across
`CLAUDE.md`, `.claude/rules/` and nested files creates a risk a single file did not have. Read
the rules end to end whenever one is added.

---

# Part 3 — Git as the history layer

This is where most of the documentation burden goes to die, if you let it. History is already
being recorded on every commit. The only question is whether it is recorded in a form anything
can read later.

## 3.1 Structured commit messages

Conventional Commits 1.0.0 defines the shape:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Footers follow `token: value`, where the token uses hyphens instead of spaces. Breaking changes
are marked either by a `BREAKING CHANGE:` footer or a `!` before the colon. The specification
lists structured project exploration and automatic changelog generation among the benefits.

This is what turns history from free text into queryable data.

## 3.2 Trailers as lightweight decision records

Most decisions do not deserve a file. They deserve to be attached to the change that implements
them:

```
feat(auth): move session store to Redis

The single-process cache could not be shared across replicas.

Decision: chose Redis over sticky sessions because the load balancer
  configuration is managed by another team and cannot be changed.
Rejected: sticky sessions, in-process cache with gossip
Refs: #241
```

Retrieval:

```bash
git log --grep='^Decision:' --pretty=format:'%h %ad %s%n%b' --date=short
```

**The rule that decides file versus trailer:** if reversing the decision is cheap and local, it
belongs in a trailer. If reversing it is expensive and touches multiple parts of the system, it
gets an ADR file, because the value of an ADR is the Context section and nobody writes three
paragraphs of context in a commit message.

## 3.3 `git notes` for knowledge that arrives late

Notes attach information to an existing commit **without modifying the commit**. They are stored
as refs under `refs/notes/`, by default `refs/notes/commits`, and `git log` displays them under
the original message.

```bash
git notes add -m 'Confirmed with the original author 2026-08-15: the retry loop
exists because the upstream API returned 502 under load. Not a workaround for
our own bug.' <commit>

git notes show <commit>
```

This is the right home for anything you learn *after* the fact: why an old change was really
made, what an undocumented constant means, what a past author confirmed when asked. Rewriting
history to add it is destructive; a note is not.

**The trap: notes are not transferred by default on push, fetch or clone.** They need an explicit
refspec:

```bash
git config remote.origin.fetch '+refs/notes/*:refs/notes/*'
git push origin refs/notes/commits
```

This matters most wherever a repository is consumed outside the normal fetch path: mirrors,
archives, bundles, or a second party working from a copy. In those setups the notes silently do
not arrive, and nothing signals their absence. Verify explicitly that `refs/notes/*` is included
in whatever transfer mechanism you use.

## 3.4 Annotated tags for the release timeline

A "release history" section in markdown goes stale the moment someone ships without editing it.
An annotated tag carries its own message and cannot be forgotten, because tagging is part of
shipping.

```bash
git tag -a v2.4.0 -m 'Adds the batch import path. Drops support for the legacy CSV format.'
git log --tags --simplify-by-decoration --pretty='%ad %d %s' --date=short
```

## 3.5 What git cannot hold

Be clear about the boundary, or you will try to push things into git that do not fit:

- **Open questions.** An unresolved state is not an event. There is no commit at which "we do
  not know how these two systems interact" happened.
- **Rules and conventions.** A rule is not an event either, and it must be in context every
  session, which git never is.
- **Current-state knowledge.** Reconstructing it means replaying history.

## 3.6 The cost, stated plainly

Git-as-memory is worth exactly as much as your commit messages. In agent-assisted development
the natural drift is toward `wip`, `fix`, and `update`. If that is what the log contains, this
entire part produces nothing and you have removed documentation without replacing it.

**So this is not a way to do less work. It is a way to move the work to where it is cheaper: from
writing documents after the fact to writing three good lines at the moment you already have the
context loaded.** That trade only pays if the format is enforced, which is Part 4.

---

# Part 4 — Enforcement and drift control

**State the limit first: documents cannot enforce anything.** Claude Code's documentation is
explicit that memory files are *context, not enforced configuration*, and that to block an action
regardless of what the model decides you must use a hook. Everything in Parts 1 to 3 is a
request. Everything here is a mechanism.

| Concern | Convention alone | With a mechanism |
|---|---|---|
| Detect a doc is behind the code | yes, via `basis_commit` | yes |
| Detect an unsourced claim | yes, via markers | yes |
| Prevent a doc going stale | **no** | yes, CI blocks the merge |
| Prevent unusable commit messages | **no** | only in CI — see 4.1; the `commit-msg` hook is fast feedback, not enforcement |
| Prevent editing an accepted ADR | **no** | yes, `PreToolUse` hook |
| Survive context compaction | **no** | yes, `SessionStart` hook |

## 4.1 Versioned git hooks

`.git/hooks` is not committed, so hooks placed there exist only on one machine. Point git at a
tracked directory instead, once per clone:

```bash
git config core.hooksPath .githooks
```

**That line is the catch, and it is why this hook is not enforcement.** `core.hooksPath` is local
config: it is not committed and it does not travel with a clone. Anyone who clones the repository
gets the hook file and no hook execution, with no warning of any kind, and `git commit --no-verify`
skips it even where it is configured. Treat it as fast local feedback — a typo caught in the second
before it becomes history. If the commit format has to hold for everyone, the same check has to run
server-side in CI, over the commits in the pull request. Write the setup line into `CLAUDE.md` so a
new clone can find it without being told.

`.githooks/commit-msg` (must be `chmod +x`):

```bash
#!/usr/bin/env bash
# Enforce Conventional Commits. Without this, Part 3 is decorative.
set -euo pipefail
MSG_FILE="$1"
FIRST_LINE="$(head -n1 "$MSG_FILE")"

# allow merge and revert commits through untouched
grep -qE '^(Merge|Revert)' <<<"$FIRST_LINE" && exit 0

if ! grep -qE '^(feat|fix|docs|refactor|perf|test|build|ci|chore)(\([a-z0-9._/-]+\))?!?: .{1,}' <<<"$FIRST_LINE"; then
  cat >&2 <<'EOF'
Rejected: commit subject must follow Conventional Commits.
  <type>[optional scope]: <description>
  types: feat fix docs refactor perf test build ci chore
EOF
  exit 1
fi

if [ "${#FIRST_LINE}" -gt 72 ]; then
  echo "Rejected: subject line is ${#FIRST_LINE} characters, limit is 72." >&2
  exit 1
fi
exit 0
```

## 4.2 CI check: docs coupled to the paths they describe

The core anti-drift rule: *if code under a documented path changed and the document did not, the
change does not merge.* This is the only mechanism that reliably catches silent drift.

`scripts/check-docs.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
BASE="${1:-origin/main}"
CHANGED="$(git diff --name-only "$BASE"...HEAD)"
STATUS=0

for doc in docs/knowledge/*.md; do
  paths="$(awk '/^covers_paths:/{f=1;next} /^[a-z_]+:/{f=0} f&&/^ *- /{sub(/^ *- /,"");print}' "$doc")"
  [ -z "$paths" ] && continue

  doc_touched=false
  echo "$CHANGED" | grep -qx "$doc" && doc_touched=true

  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if echo "$CHANGED" | grep -q -- "${p%%\**}" && [ "$doc_touched" = false ]; then
      echo "DRIFT: $p changed but $doc was not updated" >&2
      STATUS=1
      break
    fi
  done <<< "$paths"
done
exit $STATUS
```

## 4.3 CI check: staleness budget

```bash
#!/usr/bin/env bash
set -euo pipefail
MAX_BEHIND="${MAX_BEHIND:-200}"

for doc in docs/knowledge/*.md; do
  basis="$(awk -F': *' '/^basis_commit:/{print $2; exit}' "$doc")"
  [ -z "$basis" ] && { echo "MISSING basis_commit: $doc" >&2; continue; }
  git cat-file -e "${basis}^{commit}" 2>/dev/null || { echo "UNKNOWN commit in $doc: $basis" >&2; continue; }
  behind="$(git rev-list --count "${basis}"..HEAD)"
  [ "$behind" -gt "$MAX_BEHIND" ] && echo "STALE: $doc is $behind commits behind" >&2
done
```

Start as a warning, promote to a hard failure once the numbers are honest.

## 4.4 Agent hook: protect files that must not be edited

Verified configuration shape. In `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh"
          }
        ]
      }
    ]
  }
}
```

`.claude/hooks/protect-files.sh` (must be `chmod +x`):

```bash
#!/usr/bin/env bash
FILE_PATH="$(jq -r '.tool_input.file_path // empty')"
PROTECTED=("docs/decisions/" ".env" "infra/prod")

for pattern in "${PROTECTED[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH is protected. Accepted decisions are immutable; supersede instead." >&2
    exit 2
  fi
done
exit 0
```

Exit-code semantics from the documentation: **exit 2 blocks the action** and stderr is fed back
to the model as feedback; **exit 0 makes no decision** and the normal permission flow continues.
For richer control, exit 0 and print a `hookSpecificOutput` object with a `permissionDecision` of
`allow`, `deny` or `ask`. Do not mix the two styles in one hook.

This is what makes decision-record immutability real rather than aspirational.

## 4.5 Agent hook: survive compaction

Long sessions get compacted and instructions given only in conversation are lost. A
`SessionStart` hook with the `compact` matcher re-injects what must not be forgotten; stdout is
added to the model's context.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "cat docs/knowledge/07-open-questions.md; git log --oneline -5"
          }
        ]
      }
    ]
  }
}
```

Project-root `CLAUDE.md` is re-read after compaction on its own. Nested rules and path-scoped
rules are not, which is what this hook covers.

## 4.6 What still cannot be enforced

No mechanism here can tell you a document is *wrong* rather than merely *old*, that a confidence
marker was applied truthfully, or that an open question was resolved rather than quietly deleted.
Those need a human or an agent re-reading against primary sources on a real cadence. The
mechanisms buy attention. They do not buy correctness.

---

# Part 5 — Local durability: what survives and what silently does not

Everything above assumes the memory is still there tomorrow. Sort every artifact into one of
three tiers and know which tier each one is in.

| Tier | Where | Survives | Restored by |
|---|---|---|---|
| **A. Committed** | in the repo, tracked | machine loss, fresh clone, handover | `git clone` |
| **B. Ignored** | in the repo, gitignored | nothing but this working copy | nothing |
| **C. Outside** | agent state in your home directory | only this machine | nothing |

**Tier A is the only real memory.** `CLAUDE.md`, `.claude/rules/`, `.claude/settings.json`,
`.githooks/`, `scripts/`, all of `docs/`, plus the commits, tags and notes. Commit the agent
configuration; it is project knowledge, not personal setup.

**Tier B is personal scratch.** `CLAUDE.local.md` is designed for per-machine preferences and is
meant to be gitignored. Anything in it is gone on a fresh clone, and in a multi-worktree setup it
exists only in the worktree where it was created. Nothing you would be unhappy to lose belongs
here.

**Tier C is the one that surprises people.** Claude Code's auto memory, the notes the agent
writes for itself, lives in your home directory under `~/.claude/projects/<project>/memory/`, and
the documentation states plainly that it is **machine-local and not shared across machines or
cloud environments**. It is excluded from the transcript retention sweep, so it persists on that
machine, but it is not in your repository and it is not in any project backup. A new laptop
starts with none of it.

**The rule that follows: run a promotion pass.** Auto memory is where the agent accumulates what
it learned by working. Periodically read it, and move anything that is genuinely project
knowledge into Tier A: a recurring pitfall becomes a rule in `CLAUDE.md`, a discovered constraint
becomes a line in a knowledge file, a resolved uncertainty leaves `07-open-questions.md`. What
you do not promote, you lose on the next machine.

## Offline snapshots

A repository already is a backup, provided a copy exists somewhere other than the disk it lives
on. For a single-file archive of the entire history:

```bash
git bundle create project-$(date +%Y%m%d).bundle --all
git bundle verify project-20260815.bundle
```

Two cautions. A bundle carries the refs you ask it for, so confirm for yourself that
`refs/notes/*` is included before relying on it to carry your notes; do not assume it. And
`--all` does not include untracked or ignored files, so Tier B and Tier C are not in it, by
design.

## The five-minute recovery test

Do this once, and again after any change to the layout. Clone the repository into a clean
directory, open an agent session there, and ask it three questions:

1. What is this project and what is its current state?
2. Why was <some non-obvious choice> made this way?
3. What do we not know yet?

If it cannot answer all three from the clone alone, your memory is not in Tier A. The answer will
usually be in your head, on your machine, or in a chat log. That is the gap this whole template
exists to close.

---

# Skeletons

## `CLAUDE.md`

```markdown
# <Project> — agent instructions

> **As of:** YYYY-MM-DD · **Basis:** commit `xxxxxxx`

## What this is
Two or three sentences. What the system does, for whom, and its lifecycle stage.

## Hard rules
1. Budgets: CLAUDE.md 200 lines, knowledge files 150, ADRs 60.
2. Accepted decision records are never edited. Supersede with a new one.
3. Every non-obvious claim carries [F]/[I]/[U] plus a source and a date.
4. Contradictions go to docs/knowledge/07-open-questions.md. Do not resolve by guessing.
5. Do not document what can be derived from the code.
6. Commits follow Conventional Commits. Non-obvious choices get a `Decision:` trailer.

## Conventions
- Confidence markers: [F] fact / [I] inference / [U] unverified
- Branching, naming, review expectations

## Commands
- Build / Test / Lint: `...`
- Docs check: `./scripts/check-docs.sh`
- Decision log: `git log --grep='^Decision:'`

## Where to look
| I need... | Read |
|---|---|
| what the system is | `docs/knowledge/01-identity.md` |
| where a claim came from | `docs/knowledge/02-sources.md` |
| how it is built | `docs/knowledge/03-architecture.md` |
| what runs where | `docs/knowledge/05-operations.md` |
| why an architectural choice was made | `docs/decisions/` |
| why a local implementation choice was made | `git log --grep='^Decision:'` |
| what we do not know | `docs/knowledge/07-open-questions.md` |

## Do not
Things that look reasonable but are wrong here, each with its one-line reason.
```

## `docs/knowledge/03-architecture.md`

arc42's 12 sections. Use only the ones that carry content; an empty section is worse than an
absent one.

1. Introduction and goals · 2. Constraints · 3. Context and scope · 4. Solution strategy ·
5. Building block view · 6. Runtime view · 7. Deployment view · 8. Crosscutting concepts ·
9. Architectural decisions (link to `docs/decisions/`, do not duplicate) · 10. Quality
requirements · 11. Risks and technical debt · 12. Glossary

For a small system, sections 1, 3, 5, 7 and 11 carry most of the value.

## `docs/decisions/NNNN-<slug>.md`

Michael Nygard's ADR format. One decision per file, sequential number, never renumbered.

```markdown
# NNNN. <Short title of the decision>

**Status:** proposed | accepted | deprecated | superseded by [NNNN](NNNN-<slug>.md)
**Date:** YYYY-MM-DD

## Context
The forces at play: technical, organisational, political, project-local. Value-neutral
language, describing the situation rather than defending the outcome. This is the
section still worth reading in three years.

## Decision
"We will ..." Active voice, one clear statement.

## Consequences
What becomes easier, what becomes harder, what becomes newly possible. Positive and
negative both. This is not a justification section.
```

A superseded record is marked superseded, never deleted. The record of a wrong turn is often
worth more than the record of the right one, because it stops the turn being taken twice.

## `docs/knowledge/07-open-questions.md`

```markdown
| # | Question | Why it matters | Blocked on | Raised | Status |
|---|---|---|---|---|---|
| 1 | When two config sources disagree, which wins? | production may not match staging | access to prod config | 2026-01-14 | open |
| 2 | Who owns the scheduled job runner? | nobody is on call for it | asking ops | 2026-01-20 | open |
```

- A contradiction between two sources is an open question, not a fact to be chosen between
- "Nobody knows" and "it was never recorded" are valid resolutions, written down as such with the
  date they were established
- Nothing leaves this file without either evidence or an explicit decision to stop asking

## `docs/knowledge/02-sources.md`

```markdown
| Source | Type | Location | Captured | Status |
|---|---|---|---|---|
| Design brief v2 | document | `docs/sources/design-brief-v2.md` | 2026-01-14 | current |
| Design brief v1 | document | `docs/sources/superseded/` | 2025-11-02 | superseded |
```

Superseded sources are moved, not deleted. Knowing a claim came from a document since replaced is
itself information, and it is the first thing you want when the claim turns out to be wrong.

---

# Adopting this on an existing project

In order. Each step is useful on its own; stop wherever the return flattens.

1. Write `CLAUDE.md`, under 200 lines, with the routing table. One hour.
2. Turn on `core.hooksPath` and the `commit-msg` hook. From here, history starts accumulating in
   a readable form whether or not you do anything else.
3. Create `07-open-questions.md` and fill it with everything currently unclear. This is usually
   the most immediately useful file in the set.
4. Write `03-architecture.md` for the sections that have real content.
5. Add the CI drift check as a warning. Promote to blocking once it is quiet.
6. Add the agent hooks.
7. Run the five-minute recovery test. Fix what it exposes.

---

# Adapting to other agent tooling

Everything under `docs/`, and all of Part 3, is portable. Only two things are tool-specific: the
name of the always-loaded instruction file, and the agent hooks in 4.4 and 4.5.

- `AGENTS.md` is an open format used by 60,000+ projects and supported by 30+ agents, now
  stewarded by the Agentic AI Foundation under the Linux Foundation.
- Claude Code reads `CLAUDE.md`, not `AGENTS.md`. To serve both without duplication, make
  `CLAUDE.md` a single `@AGENTS.md` line followed by any tool-specific additions, or symlink
  where the platform allows it.
- The git hooks and CI checks work with any agent, or none.

Keep knowledge in plain markdown and history in git. The moment either lives in a tool-specific
format it stops being portable and starts being a dependency.

---

# What is standard here and what is not

**From published standards and established conventions:**

- The 12-section architecture skeleton is arc42
- The decision record format is Michael Nygard's ADR, collected at adr.github.io
- The commit message structure, footer format and breaking-change rules are Conventional
  Commits 1.0.0
- `git notes` behaviour, its `refs/notes/` storage and the fact that it is not transferred without
  an explicit refspec, come from the git documentation
- The `AGENTS.md` format, its adoption and governance
- The 200-line target, load order, path-scoped rule behaviour, `/doctor` trimming, the "context,
  not enforced configuration" limit, hook configuration shape, hook exit-code semantics, and the
  machine-local scope of auto memory all come from the Claude Code documentation
- Separating documentation by purpose rather than topic is the Diátaxis principle
- ISO/IEC/IEEE 42010:2022 governs architecture descriptions; arc42 sits under it as a practical
  template
- ISO 30401:2018 specifies requirements for knowledge management systems at the organisational
  level, above any single project

**Not from a standard. Proposed on judgement, argue with it before adopting:**

- The four-way split of memory in Part 0, and the file-versus-git allocation
- The `[F]` `[I]` `[U]` confidence markers
- Treating open questions as a first-class file
- The staleness header carrying a review *trigger* rather than a review date
- Recording contradictions instead of resolving them by plausibility
- The numeric budgets, the event-driven trigger table, the `covers_paths` drift check, the
  three-tier durability model, and the five-minute recovery test
- All scripts here are illustrative and have not been run against a real repository. Test them on
  a branch before making any of them a required check.

---

# References

- arc42 template — https://arc42.org/overview/
- Architectural Decision Records — https://adr.github.io/
- Conventional Commits 1.0.0 — https://www.conventionalcommits.org/en/v1.0.0/
- git-notes — https://git-scm.com/docs/git-notes
- AGENTS.md — https://agents.md/
- Claude Code memory documentation — https://code.claude.com/docs/en/memory
- Claude Code hooks guide — https://code.claude.com/docs/en/hooks-guide
- Diátaxis — https://diataxis.fr/
- ISO/IEC/IEEE 42010:2022 — https://www.iso.org/standard/74393.html
- ISO 30401:2018 — https://www.iso.org/standard/68683.html
