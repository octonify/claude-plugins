# 0003. Each plugin carries its own version in its own manifest

**Status:** accepted
**Date:** 2026-08-16

## Context

Claude Code decides whether an installed plugin needs updating by comparing the `version` string.
If `version` is set — in the plugin's `plugin.json`, or in its entry in `marketplace.json` — the
plugin is pinned to that string, and **users receive an update only when the string changes**.
Pushing a commit is not enough. A fix shipped without a version bump reaches nobody.

Both locations work, and setting it in both is a chance for the two to disagree. The catalog-level
option is tempting because one file lists every plugin, but it puts a plugin's release state
outside the plugin's own directory: reviewing a plugin's diff would not show whether it was
released, and moving the plugin to its own repository ([0001](0001-single-repository-marketplace.md))
would leave its version behind.

A single repository-wide version — one number covering all plugins — would mean every release of
any plugin registers as an update to every other. Users of an untouched plugin would see churn
with no change in behaviour, and the version number would stop describing the thing it is attached
to.

## Decision

We will set `version` only in `plugins/<name>/.claude-plugin/plugin.json`, one per plugin,
following Semantic Versioning, and never in `marketplace.json`.

## Consequences

- Releasing one plugin never pushes an update to users of another.
- A plugin's version, changelog and code sit in one directory and move together if the plugin is
  ever extracted to its own repository.
- Every release requires remembering the bump, and nothing in the tooling enforces it. This is the
  single most likely mistake in this repository, which is why it is stated in `CLAUDE.md` and why
  the release procedure lists it as a numbered step. A check that fails when a plugin directory
  changes without its `version` changing is the obvious mitigation; it waits until the bump has
  actually been forgotten once.
- Plugins start at `0.1.0` rather than `1.0.0` when their design has not been validated in real
  use. The version is a claim about stability and should be an honest one.
- Version and git tag are two separate records of the same release. See
  [0004](0004-scoped-git-tags.md).
