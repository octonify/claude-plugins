# 0001. One repository holds the marketplace and all its plugins

**Status:** accepted
**Date:** 2026-08-16

## Context

Claude Code distributes plugins through marketplaces. The catalog is a
`.claude-plugin/marketplace.json` at a repository root, and each plugin entry names a `source`.
That source may be a path inside the same repository, or an external repository, npm package,
archive or git subdirectory. So the catalog and the plugins it lists may live together or apart,
and the choice is made per entry.

The situation here: a single author, an expected handful of plugins, and release tooling — hooks,
tags, CI — that would otherwise be duplicated into every new repository. Against that, plugins in
separate repositories get independent issue trackers, independent stars and clone counts, and a
commit log that is not shared with unrelated work.

The decision is reversible. Moving a plugin to its own repository changes one `source` line in
`marketplace.json` from a path to a repository object. Users keep the same
`/plugin marketplace add` and `/plugin install` commands and see nothing.

## Decision

We will keep the marketplace catalog and every plugin in one repository,
`octonify/claude-plugins`, with each plugin in its own directory under `plugins/`.

## Consequences

- One clone, one set of hooks, one release procedure, one place to look.
- A plugin cannot reference files outside its own directory. Installation copies only the plugin
  directory, so a path like `../shared` resolves to nothing on the user's machine. Shared content
  is duplicated per plugin.
- The commit log mixes work on unrelated plugins. Conventional Commits scopes
  (`feat(project-memory): ...`) are what keeps it readable, which makes the commit-msg hook load-bearing
  rather than decorative.
- Issues and stars are repository-wide, so per-plugin popularity is not separately visible.
- Reversing this affects the maintainer only, never an installed user. See [0003](0003-independent-plugin-versions.md)
  and [0004](0004-scoped-git-tags.md) for the machinery that keeps plugins independent inside the
  shared repository.
