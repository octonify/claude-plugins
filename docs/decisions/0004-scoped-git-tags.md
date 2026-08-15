# 0004. Git tags are scoped per plugin

**Status:** accepted
**Date:** 2026-08-16

## Context

Tags name points in history. In a repository holding one shippable artifact, `v0.2.0` is
unambiguous. In this repository ([0001](0001-single-repository-marketplace.md)) several plugins are
versioned independently ([0003](0003-independent-plugin-versions.md)), so a bare `v0.2.0` names a
version without naming what was versioned. Two plugins reaching `0.2.0` at different times cannot
both hold the tag, and the first one to claim it makes the number unavailable to the other for
reasons that have nothing to do with either.

Tags are also the only release record that cannot be forgotten, because tagging is part of
shipping — unlike a "release history" section in markdown, which goes stale the moment someone
ships without editing it. That property is only worth having if the tag identifies its subject.

Annotated tags carry their own message and their own author and date. Lightweight tags do not,
and a release marker with no message is a pointer with no content.

## Decision

We will tag releases as `<plugin-name>-v<version>`, for example `project-memory-v0.2.0`, always
annotated (`git tag -a`), and never use a bare `v<version>` tag in this repository.

## Consequences

- Every tag says what it released. `git tag --list 'project-memory-*'` gives one plugin's release
  history; `git tag` gives all of them.
- Two plugins can hold the same version number without conflict.
- GitHub's automatic "latest release" ordering across mixed tag prefixes is not meaningful here.
  Release pages are per plugin, read through the prefix filter, not through "latest".
- Tooling that assumes `v*` tags — changelog generators, some CI release actions — needs its
  pattern configured rather than left at the default.
- The tag is written after the `version` bump and the CHANGELOG entry are committed, so the tag
  points at a commit where all three agree. `git push --follow-tags` sends the commit and the
  annotated tag together, which is why the release procedure specifies that flag.
