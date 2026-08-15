# 0002. The marketplace is named after the owner, not after a plugin

**Status:** accepted
**Date:** 2026-08-16

## Context

The marketplace `name` is public-facing and permanent in practice. Users type it on every install:
`/plugin install <plugin>@<marketplace>`. Each user can register only one marketplace per name,
and a second registration under the same name replaces the first — so a name collision is not a
warning, it is a silent replacement.

At the point of this decision the repository holds one plugin, `project-memory`. Naming the
marketplace after it would read correctly today and wrongly the moment a second, unrelated plugin
is added: users would be installing something with no connection to project memory from a
catalog called `project-memory`.

Renaming later is not free. It is a new marketplace from the user's point of view: they must remove
the old one and add the new one, and every install command in every README and issue thread
becomes wrong.

Anthropic reserves a list of marketplace names for official use, including `claude-code-plugins`,
`anthropic-plugins` and `agent-skills`, and blocks names that impersonate official sources. A
generic descriptive name such as `claude-plugins` also risks colliding with another author's
catalog on a user's machine.

## Decision

We will name the marketplace `octonify`, after the owner, and never after any plugin it contains.

## Consequences

- Any future plugin joins the catalog without the name contradicting the contents.
- The install command is stable for the life of the marketplace. No user ever has to re-add it.
- The name carries no information about what the catalog contains; the README plugin table and the
  marketplace `description` field carry that instead.
- An owner-scoped name is unlikely to collide with another author's registration, and cannot be
  mistaken for an official Anthropic source.
- The repository name (`claude-plugins`) and the marketplace name (`octonify`) differ. This is
  intentional and is why `/plugin marketplace add octonify/claude-plugins` installs a marketplace
  called `octonify`.
