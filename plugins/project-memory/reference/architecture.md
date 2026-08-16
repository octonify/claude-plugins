# Why the structure is shaped this way

Reference material for the `init` and `audit` skills. Read this only when a choice has to be
adapted to a repository that does not fit the defaults, or defended to a user who disagrees with
the rule behind it. The skills carry the procedure; this file carries the argument.

Derived from `project-memory-structure-template.md` v3.0 (2026-08-15), kept in the marketplace
repository root for provenance.

---

## 1. Memory is four things, not one

| Memory | Question it answers | Home | Why there |
|---|---|---|---|
| Instructions | how do we work here | `CLAUDE.md`, `.claude/rules/` | must be loaded every session |
| Knowledge | what is true now | `docs/knowledge/*.md` | must be readable in one pass |
| History | what changed and why | git commits, trailers, notes, tags | already an event log, free |
| Decisions | why the system is shaped this way | `docs/decisions/*.md` | the value is in the context paragraphs |

The organising principle: **git is an excellent event log and a terrible current-state document.**
Learning "what is true now" from git means replaying history. Learning "what changed and why" from
a markdown file means hand-maintaining a changelog, which drifts. Each covers the other's weakness
exactly.

The failure this avoids is a single long memory file: too long to load every session, too
summarised to serve as a reference, and internally at war over whether superseded content is
overwritten or preserved.

**When adapting:** the four-way split is judgement, not a standard. What is not negotiable is that
current state and history live in different places. Merging them back together is how the failure
above returns.

---

## 2. Why `CLAUDE.md` is capped at 200 lines

An always-loaded instruction file is paid for on every session, and its length trades directly
against how reliably the agent follows it. Claude Code's documentation states the 200-line target
explicitly, and notes that `@path` imports load at launch alongside the parent file — so splitting
by import organises content but does not reduce context cost. Only path-scoped rules
(`.claude/rules/*.md` with `paths:` frontmatter) and on-demand skills actually reduce it.

`/doctor` proposes the same trim the guards below describe: cut directory layouts, dependency
lists and architecture overviews the model can derive; keep pitfalls, rationale and conventions
that differ from tool defaults.

**When adapting:** a monorepo is the common case for going over budget. The answer is path-scoped
rules per package, not a longer `CLAUDE.md`.

---

## 3. The four guards against over-documentation

A template is a schema, and agents fill schemas. Nine empty files read as nine assignments. The
predictable result is decision records for trivial choices, an open-questions file that becomes a
to-do list, and pages restating what the code already says.

The real cost is not disk. It is retrieval: the larger the corpus, the higher the chance the agent
reads the wrong document or a stale one. Documentation has a negative-return region and it is easy
to reach.

**Guard 1 — start with three files.** `CLAUDE.md`, `03-architecture.md`, `07-open-questions.md`.
Every other file is created the day it has real content. This is why `init` offers the rest rather
than creating them.

**Guard 2 — numeric budgets, not adjectives.** An agent respects "max 150 lines". It does not
respect "be concise". Over budget means split by topic or delete.

**Guard 3 — documentation is event-driven, not schema-driven.** Each artifact has exactly one
trigger. No trigger, no document.

| Write this | Only when |
|---|---|
| a commit trailer | any non-obvious implementation choice, recorded where it happened |
| an ADR file | the decision is architectural, expensive to reverse, and needs paragraphs of context |
| an open question | two sources disagree, or a needed fact has no source at all |
| a knowledge file edit | something true yesterday is false today |
| a rule in `CLAUDE.md` | the agent got it wrong once, or a review caught something it should have known |
| a `.claude/rules/` file | the instruction applies to a subset of paths, not the whole repo |

**Guard 4 — review the rule set for contradictions.** When two rules contradict, the model may
pick one arbitrarily. Splitting rules across `CLAUDE.md`, `.claude/rules/` and nested files creates
a risk a single file did not have. Read the rules end to end whenever one is added.

---

## 4. The cross-cutting conventions, and what each one buys

**Confidence markers.** `[F]` fact stated in a named source · `[I]` inference drawn from sources
but not stated in them · `[U]` unverified. A claim with no source is an inference and must be
marked as one. This single rule is what stops a knowledge base drifting into fiction. Not from any
standard; proposed on judgement.

**Source and date on every claim**, in the form `[F, src/config/loader.ts:88, 2026-01-14]`. The
date is what makes a wrong claim traceable to the moment it stopped being right.

**Staleness header** carrying a review *trigger*, not a review date. "Reviewed quarterly" decays
silently. "Wrong as soon as the deployment target changes" does not. `covers_paths` is the field
the drift check reads; an entry pointing nowhere makes the check pass vacuously, which is why
`audit` tests it.

**Current state and history separated by file, not by section.** A changelog section inside a
current-state document is a contradiction and will surface as one.

**Do not document what an agent can derive.** Directory listings, dependency lists and generated
inventories go stale and cost context for nothing. This is the single most effective anti-drift
measure available: what was never written cannot go stale.

**Contradictions are recorded, not resolved by preference.** When two sources disagree, the
disagreement is the finding. It goes to `07-open-questions.md` until evidence settles it. Choosing
the more plausible one and moving on is how a corpus acquires confident errors.

**Filenames must be honest.** If `03-architecture.md` contains operations content, the routing
table breaks *silently*: the agent opens the right file, does not find the answer, and guesses
instead of reporting. This is the worst failure mode in the structure because it emits no signal.
Content that does not match its filename is moved, not appended to.

---

## 5. Git as the history layer

**Conventional Commits 1.0.0** gives the shape: `<type>[optional scope]: <description>`, footers
as `token: value` with hyphens instead of spaces, breaking changes marked by a `BREAKING CHANGE:`
footer or a `!` before the colon. This is what turns history from free text into queryable data.

**Trailers as lightweight decision records.** Most decisions do not deserve a file; they deserve
to be attached to the change that implements them.

```
feat(auth): move session store to Redis

The single-process cache could not be shared across replicas.

Decision: chose Redis over sticky sessions because the load balancer
  configuration is managed by another team and cannot be changed.
Rejected: sticky sessions, in-process cache with gossip
Refs: #241
```

Retrieved with `git log --grep='^Decision:' --pretty=format:'%h %ad %s%n%b' --date=short`.

**The rule that decides file versus trailer:** if reversing the decision is cheap and local, it
belongs in a trailer. If reversing it is expensive and touches several parts of the system, it gets
an ADR file — because the value of an ADR is the Context section, and nobody writes three
paragraphs of context in a commit message.

**`git notes` for knowledge that arrives late.** Notes attach information to an existing commit
without modifying it, stored under `refs/notes/` (by default `refs/notes/commits`) and displayed
by `git log` under the original message. This is the right home for anything learned *after* the
fact: why an old change was really made, what an undocumented constant means, what a past author
confirmed when asked. Rewriting history to add it is destructive; a note is not.

**The trap:** notes are not transferred by default on push, fetch or clone. They need an explicit
refspec, `git config remote.origin.fetch '+refs/notes/*:refs/notes/*'` and
`git push origin refs/notes/commits`. This matters most wherever a repository is consumed outside
the normal fetch path — mirrors, archives, bundles, a second party working from a copy. The notes
silently do not arrive and nothing signals their absence.

**Annotated tags for the release timeline.** A "release history" section in markdown goes stale the
moment someone ships without editing it. An annotated tag carries its own message and cannot be
forgotten, because tagging is part of shipping.

**What git cannot hold:** open questions (an unresolved state is not an event), rules and
conventions (also not events, and they must be in context every session), and current-state
knowledge (reconstructing it means replaying history).

**The cost, stated plainly.** Git-as-memory is worth exactly as much as the commit messages. In
agent-assisted development the natural drift is toward `wip`, `fix` and `update`. If that is what
the log contains, this whole layer produces nothing and documentation has been removed without
being replaced. It is not a way to do less work; it is a way to move the work to where it is
cheaper — from writing documents after the fact to writing three good lines at the moment the
context is already loaded. That trade only pays if the format is enforced.

---

## 6. Enforcement, and its limits

**Documents cannot enforce anything.** Memory files are context, not enforced configuration. To
block an action regardless of what the model decides, a hook is required.

| Concern | Convention alone | With a mechanism |
|---|---|---|
| Detect a doc is behind the code | yes, via `basis_commit` | yes |
| Detect an unsourced claim | yes, via markers | yes |
| Prevent a doc going stale | no | yes, CI blocks the merge |
| Prevent unusable commit messages | no | only in CI; the `commit-msg` hook is fast feedback, not enforcement |
| Prevent editing an accepted ADR | no | yes, `PreToolUse` hook |
| Survive context compaction | no | yes, `SessionStart` hook |

`.git/hooks` is not committed, so hooks placed there exist on one machine only. `core.hooksPath`
pointing at a tracked directory is what makes the hook *file* survive a clone — but the setting
itself is local config and must be set once per clone, which is the one manual step this structure
cannot remove.

**The local hook is not enforcement, and calling it that is the mistake.** It runs only where
someone ran `git config core.hooksPath .githooks`, and `git commit --no-verify` skips it. A clone
that never ran the line accepts every malformed subject in silence, and the first sign of it is a
`git log --grep='^Decision:'` that returns nothing a year later. Treat the hook as what it is: a
fast local check that catches a typo in the second before it becomes history.

**Recommended, not shipped: a CI check on commit subjects.** If the format has to hold for
everyone, validate it server-side — a job on pull requests that runs the same
`^(feat|fix|docs|...)(\(scope\))?!?: ` match over the commits in the range, using the same
`.githooks/commit-msg` file as its implementation so the two cannot disagree. This plugin does not
install such a workflow. CI shape is per-project (provider, trigger, required-check
configuration), a generated workflow file is the kind of thing that is merged unread, and a check
that blocks the day it lands on a repository with an existing backlog gets deleted rather than
satisfied. Recommend it, once, in `init`'s report; let the project write it.

Hook exit-code semantics: **exit 2 blocks the action** and stderr is fed back to the model as
feedback; **exit 0 makes no decision** and the normal permission flow continues. For richer
control, exit 0 and print a `hookSpecificOutput` object with a `permissionDecision` of `allow`,
`deny` or `ask`. Do not mix the two styles in one hook.

`SessionStart` with the `compact` matcher re-injects what must not be forgotten after compaction;
stdout is added to the model's context. Project-root `CLAUDE.md` is re-read after compaction on its
own — nested and path-scoped rules are not, which is what that hook covers.

**Why the CI checks ship as warnings.** A blocking check installed on day one fails on the existing
backlog, and the first response to a check that always fails is to disable it. Both scripts exit 0
on findings and only fail under `STRICT=1`. Promote once the output is quiet, as a separate,
deliberate decision.

**Exit-code contract of the two scripts** — unrelated to the Claude Code hook codes above, which
are a different mechanism:

| Code | Meaning |
|---|---|
| 0 | the check ran, against a base it named; findings, if any, were warnings |
| 1 | findings, and `STRICT=1` was set |
| 2 | the check could **not run** — `check-docs.sh` could not determine a base ref |

`STRICT` governs whether *findings* fail the build. It has no bearing on 2: "I cannot determine
what to compare against" is not a finding, it is an inability to do the job, and it must be loud
whatever `STRICT` says. A check that inspects nothing and exits 0 is worse than no check, because
it also produces a green tick. `check-docs.sh` therefore refuses any base ref that is the
currently checked-out branch or that points at `HEAD`: `git diff <that>...HEAD` is empty by
construction, so a pass proves only that the comparison never happened.

**What still cannot be enforced:** no mechanism can tell you a document is *wrong* rather than
merely *old*, that a confidence marker was applied truthfully, or that an open question was
resolved rather than quietly deleted. Those need a human or an agent re-reading against primary
sources on a real cadence. The mechanisms buy attention. They do not buy correctness.

---

## 7. Durability: what survives and what silently does not

| Tier | Where | Survives | Restored by |
|---|---|---|---|
| A. Committed | in the repo, tracked | machine loss, fresh clone, handover | `git clone` |
| B. Ignored | in the repo, gitignored | nothing but this working copy | nothing |
| C. Outside | agent state in the home directory | only this machine | nothing |

**Tier A is the only real memory:** `CLAUDE.md`, `.claude/rules/`, `.claude/settings.json`,
`.githooks/`, `scripts/`, all of `docs/`, plus commits, tags and notes. Commit the agent
configuration; it is project knowledge, not personal setup.

**Tier B is personal scratch.** `CLAUDE.local.md` is designed for per-machine preferences and is
meant to be gitignored. In a multi-worktree setup it exists only in the worktree where it was
created.

**Tier C is the one that surprises people.** Claude Code's auto memory lives under
`~/.claude/projects/<project>/memory/` and is machine-local: not shared across machines or cloud
environments, not in the repository, not in any project backup. A new laptop starts with none of
it.

**The rule that follows: run a promotion pass.** Periodically read the auto memory and move
anything that is genuinely project knowledge into Tier A — a recurring pitfall becomes a rule in
`CLAUDE.md`, a discovered constraint becomes a line in a knowledge file, a resolved uncertainty
leaves `07-open-questions.md`. What is not promoted is lost on the next machine.

**Offline snapshots.** `git bundle create project-YYYYMMDD.bundle --all` produces a single-file
archive of the whole history. Two cautions: a bundle carries the refs asked for, so confirm
`refs/notes/*` is included rather than assuming it; and `--all` excludes untracked and ignored
files, so Tiers B and C are not in it by design.

---

## 8. The five-minute recovery test

Clone the repository into a clean directory, open an agent session there, and ask three questions:

1. What is this project and what is its current state?
2. Why was `<some non-obvious choice>` made this way?
3. What do we not know yet?

If it cannot answer all three from the clone alone, the memory is not in Tier A. The answer will
usually be in someone's head, on one machine, or in a chat log. That is the gap this structure
exists to close.

---

## 9. Adapting to other tooling

Everything under `docs/`, and all of section 5, is portable. Only two things are tool-specific: the
name of the always-loaded instruction file, and the agent hooks in section 6.

`AGENTS.md` is an open format stewarded by the Agentic AI Foundation. Claude Code reads
`CLAUDE.md`, not `AGENTS.md`. To serve both without duplication, make `CLAUDE.md` a single
`@AGENTS.md` line followed by tool-specific additions, or symlink where the platform allows it.
The git hooks and CI checks work with any agent, or none.

---

## 10. What is standard here and what is not

**From published standards and established conventions:** the 12-section architecture skeleton is
arc42; the decision record format is Michael Nygard's ADR; commit message structure, footer format
and breaking-change rules are Conventional Commits 1.0.0; `git notes` behaviour and its transfer
caveat come from the git documentation; the `AGENTS.md` format and its governance; the 200-line
target, load order, path-scoped rule behaviour, `/doctor` trimming, the "context, not enforced
configuration" limit, and hook configuration and exit-code semantics all come from the Claude Code
documentation; separating documentation by purpose rather than topic is the Diátaxis principle;
ISO/IEC/IEEE 42010:2022 governs architecture descriptions, with arc42 as a practical template
under it.

**Not from a standard — proposed on judgement, argue with it before adopting:** the four-way split
of memory and the file-versus-git allocation; the `[F]`/`[I]`/`[U]` markers; treating open
questions as a first-class file; the staleness header carrying a trigger rather than a date;
recording contradictions instead of resolving them; the numeric budgets, the event-driven trigger
table, the `covers_paths` drift check, the three-tier durability model, and the five-minute
recovery test.

## References

- arc42 — https://arc42.org/overview/
- Architectural Decision Records — https://adr.github.io/
- Conventional Commits 1.0.0 — https://www.conventionalcommits.org/en/v1.0.0/
- git-notes — https://git-scm.com/docs/git-notes
- AGENTS.md — https://agents.md/
- Claude Code memory — https://code.claude.com/docs/en/memory
- Claude Code hooks — https://code.claude.com/docs/en/hooks-guide
- Diátaxis — https://diataxis.fr/
