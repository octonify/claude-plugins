# 0006. Checks fail loudly when they cannot run

**Status:** accepted
**Date:** 2026-08-16

## Context

`project-memory` ships two checks that a scaffolded repository runs against itself. `check-docs.sh`
compares the working branch against a base ref and reports knowledge documents whose `covers_paths`
cover code that changed while the document did not. Until 0.1.0 it resolved that base ref by walking
`origin/main`, `origin/master`, `main`, `master` and taking the first that existed, falling back to
the empty tree if none did.

In a repository with no remote whose only branch is `master` — the ordinary state of a freshly
scaffolded project — that walk resolved to `master`, which is the branch already checked out.
`git diff master...HEAD` is empty by construction there, so the script printed `no changes against
master, nothing to check` and exited 0. It did that on every run, forever, and `STRICT=1` made no
difference because the exit came before `STRICT` was ever consulted. The check was not merely
failing to find drift; it had never compared anything, and it was reporting that as success.

This is worse than having no check. A check that cannot run and says nothing produces a green tick,
and a green tick is read as evidence. Every consumer of it — a person, a CI job, an agent running
`audit` — is entitled to conclude that the knowledge files were checked against the code. None of
them can see that the comparison did not happen. The same shape then turned up in four more places
in the same script and in `check-staleness.sh`, most sharply in a `git rev-list --count ... || echo
0` that recorded a failed count as zero commits behind, which is the healthiest result the check can
express: an inability to answer rendered as perfect health.

The general problem is that one value carried two meanings. "Nothing changed" and "the command
failed" were both an empty `CHANGED`; "zero commits behind" and "the count could not be taken" were
both `0`. Anywhere those collapse, the failure is indistinguishable from the healthiest possible
result, because that is the direction fallbacks are written in.

## Decision

A check that cannot determine whether it can do its job exits **2** and says why, naming what it
tried. Specifically:

- A base ref that is the branch currently checked out, or that points at `HEAD`, is not a base. It
  is rejected as the tautology it is, whether it came from the candidate walk or was passed
  explicitly. An explicit base that cannot serve is an error and never falls back to the default
  chain.
- Exit 2 means "could not run" and is independent of `STRICT`. `STRICT` governs whether *findings*
  fail the build; an inability to run is not a finding.
- No failed command is ever given a substitute value. Its exit status is kept and its own message is
  shown.

## Consequences

- **A CI job that runs the check on the trunk after a merge now hard-fails.** On the trunk,
  `origin/main` points at `HEAD` and there is nothing to compare; the old green was meaningless. Any
  such job must be given an explicit base — `HEAD~1`, or the merge commit's first parent.
- **The empty-tree fallback was removed.** It could not produce a false green, but it produced a
  drift report against a comparison nobody asked for, firing on every knowledge file at once on a
  fresh scaffold. If it is wanted back it belongs behind an explicit flag, not a fallback.
- **A freshly scaffolded repository fails its own first drift check, by design.** One branch and no
  remote means no base can exist yet. The script says exactly that, and says the scaffold is not
  broken; `init` warns of it at scaffold time as well, because one of the two is read three weeks
  later and the other is not.
- Documents the drift check skips are named on stderr, so a discarded opt-in is visible.
