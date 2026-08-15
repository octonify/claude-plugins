# claude-plugins — agent instructions

Instructions for working on **this** repository. This is not the `CLAUDE.md` that the
`project-memory` plugin installs into other projects; that template is
`plugins/project-memory/assets/CLAUDE.md.template` and the two are unrelated.

## What this is

A Claude Code **plugin marketplace**. The catalog is `.claude-plugin/marketplace.json`. Every
plugin lives in its own directory under `plugins/<name>/`, with its own manifest, its own version
and its own changelog.

Users install from it with:

```
/plugin marketplace add octonify/claude-plugins
/plugin install <plugin>@octonify
```

The marketplace is named `octonify`; the repository is named `claude-plugins`. That difference is
deliberate — see `docs/decisions/0002-generic-marketplace-name.md`.

## Hard rules

1. **A version bump goes in `plugins/<name>/.claude-plugin/plugin.json`, never in
   `marketplace.json`.** Claude Code pins an installed plugin to its `version` string. If that
   string does not change, no user receives the change, however many commits were pushed. This is
   the most likely mistake in this repository.
2. **Git tags are scoped per plugin:** `project-memory-v0.2.0`, never a bare `v0.2.0`. One
   repository holds several independently versioned plugins, so a bare semantic version does not
   say what it released. Always annotated (`git tag -a`).
3. **Each plugin has its own `CHANGELOG.md` inside its own directory.** There is no repository-wide
   changelog.
4. **Plugins cannot share files across directories.** Installing copies only the plugin's own
   directory to a cache, so `../shared/thing.sh` resolves to nothing on the user's machine.
   Duplicate the file into each plugin. Never reference `../`.
5. Inside a plugin, reference bundled files as `${CLAUDE_PLUGIN_ROOT}/assets/...`. A bare relative
   path is resolved against the user's project, not the plugin.
6. Only `plugin.json` belongs in a plugin's `.claude-plugin/` directory. Everything else —
   `skills/`, `assets/`, `reference/`, `hooks/` — sits at the plugin root.
7. Commits follow Conventional Commits, with the plugin name as the scope:
   `feat(project-memory): ...`. The log mixes unrelated plugins and the scope is what keeps it
   readable.
8. Shell scripts and git hooks are LF-only, enforced by `.gitattributes`. A CRLF hook fails on any
   non-Windows machine with `bad interpreter: /usr/bin/env bash^M`.
9. Scripts shipped as plugin assets are tested by running them before they are committed. They are
   installed on other people's machines; an illustrative script is not acceptable.

## Adding a plugin

Exactly three things change:

1. A new directory `plugins/<name>/` containing `.claude-plugin/plugin.json`, `CHANGELOG.md` and
   at least one `skills/<skill>/SKILL.md`.
2. A new entry in the `plugins` array of `.claude-plugin/marketplace.json`, with `name`, `source`
   (`./plugins/<name>`) and `description`.
3. A new row in the README plugin table.

The GitHub repository description is **not** one of them. Do not touch it as part of adding a
plugin.

## Release procedure

For a change to plugin `<name>`:

1. Make the change under `plugins/<name>/`.
2. Bump `version` in `plugins/<name>/.claude-plugin/plugin.json`. Semantic versioning. A plugin
   whose design has not been validated in real use stays below `1.0.0`.
3. Add a `CHANGELOG.md` entry under `plugins/<name>/` for that version, dated.
4. Commit, scoped: `git commit -m "feat(<name>): ..."`.
5. Tag: `git tag -a <name>-v<version> -m "<what changed, in one or two sentences>"`.
6. Push: `git push --follow-tags`.

Steps 2 and 3 are the ones that get skipped. If a change is worth pushing, it is worth a version.

## Where to look

| I need... | Read |
|---|---|
| why one repository holds every plugin | `docs/decisions/0001-single-repository-marketplace.md` |
| why the marketplace is called `octonify` | `docs/decisions/0002-generic-marketplace-name.md` |
| why versions are per plugin | `docs/decisions/0003-independent-plugin-versions.md` |
| why tags carry a plugin prefix | `docs/decisions/0004-scoped-git-tags.md` |
| what `project-memory` installs, and why | `plugins/project-memory/reference/architecture.md` |
| the source material `project-memory` was distilled from | `project-memory-structure-template.md` |

## Do not

- Do not put `version` in `marketplace.json`. It also pins, and two pinning fields will disagree.
- Do not rename the marketplace. Each user registers one marketplace per name; a rename is a new
  marketplace to every existing user and breaks every published install command.
- Do not paste `project-memory-structure-template.md` into a `SKILL.md`. It is reference material
  written to persuade a human. A `SKILL.md` carries procedure and decision rules for an agent that
  has already been told to do the job; the argument belongs in the plugin's `reference/`.
- Do not make a plugin's shipped CI check blocking by default. A check that fails on the existing
  backlog on day one gets disabled rather than fixed.
- Do not build a plugin skeleton template or path-scoped rules. Both wait until there is a second
  plugin and until a version bump has actually been forgotten once.
