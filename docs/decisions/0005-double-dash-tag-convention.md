# 0005. Plugin release tags use a double-dash separator

**Status:** accepted
**Date:** 2026-08-16

## Context

[0004](0004-scoped-git-tags.md) established that a release tag must name the plugin it released,
and chose the form `<plugin-name>-v<version>`. The separator was picked without reference to any
existing convention, because none was known to exist at the time.

One does. The Claude Code CLI ships `claude plugin tag`, which creates a `{name}--v{version}` tag
and, as it does so, validates that `plugin.json` and the enclosing `marketplace.json` entry agree
on the version. That validation is the step most likely to be skipped by hand, and it is the
mitigation named in [0003](0003-independent-plugin-versions.md) for the repository's most likely
mistake — releasing without a version bump.

A single-dash separator is also ambiguous in a way a double dash is not. Plugin names are
kebab-case, so `project-memory-v0.1.0` has no unambiguous split point: a plugin named
`project` with a version-like suffix in its name would produce the same string. `--` cannot occur
inside a kebab-case name, so `{name}--v{version}` parses in one direction only.

The cost of changing is limited to this repository's own procedure. Tags are a maintainer-facing
record; no install command, marketplace entry or plugin manifest references a tag name. At the
time of this decision exactly one tag exists, `project-memory-v0.1.0`, pushed minutes earlier with
no consumers.

## Decision

We will tag releases as `<plugin-name>--v<version>`, for example `project-memory--v0.1.0`, always
annotated, matching the format produced by `claude plugin tag`. This supersedes
[0004](0004-scoped-git-tags.md); everything else in that record — scoping per plugin, annotated
rather than lightweight, no bare `v<version>` — still holds.

## Consequences

- Releases can be made with `claude plugin tag -m "..."`, which refuses to tag when `plugin.json`
  and the marketplace entry disagree, instead of with a hand-written `git tag -a`.
- `git tag --list 'project-memory--*'` still gives one plugin's history. The filter pattern in any
  tooling or documentation gains a dash.
- The existing `project-memory-v0.1.0` tag is deleted locally and on the remote and recreated as
  `project-memory--v0.1.0` against the same commit. This is only safe because the tag is minutes
  old and nothing consumes it; a tag that has been fetched by anyone is rewritten, not deleted.
- Two conventions now appear in the history of this repository's documentation. 0004 stays in
  place, marked superseded, because the record of the turn not taken is what stops it being taken
  again.

## Notes

**2026-08-16, first exercise:** `claude plugin tag` was run for the first time, for
`project-memory--v0.2.0`. The marketplace entry carries no `version` field — this repository
forbids one — and the command accepted that silently: it reported the version from `plugin.json`
and the marketplace entry it had matched, then created the tag. The agreement check cited above
therefore fires only when both files carry a version and they disagree; an absent marketplace
`version` is not a disagreement. In this repository's configuration the validation is weaker than
the first Consequences bullet reads: the only mechanical refusal left is git's own refusal to
reuse an existing tag name.
