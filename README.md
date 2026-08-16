# octonify — Claude Code plugin marketplace

A small catalog of [Claude Code](https://code.claude.com/docs) plugins. Adding the marketplace
registers the catalog; installing a plugin copies that plugin into Claude Code and makes its
skills available as `/<plugin>:<skill>`. Each plugin is versioned on its own, so installing or
updating one has no effect on the others.

## Install

```
/plugin marketplace add octonify/claude-plugins
/plugin install project-memory@octonify
```

To update later:

```
/plugin marketplace update octonify
/plugin update project-memory@octonify
```

The first refreshes the catalog; the second is what actually moves an installed plugin to the
new version, and a restart of Claude Code applies it.

### Installing for a project

The commands above install at personal scope: one machine, one user. A repository can instead
declare the marketplace and the plugin in its checked-in `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "octonify": {
      "source": {
        "source": "github",
        "repo": "octonify/claude-plugins"
      }
    }
  },
  "enabledPlugins": [
    "project-memory@octonify"
  ]
}
```

`extraKnownMarketplaces` registers this catalog for everyone who clones the repository and trusts
the folder — no `marketplace add` needed. `enabledPlugins` names the plugins the project uses.
One caveat: as of Claude Code 2.1, a plugin from an external marketplace is not installed
automatically by that declaration; each person runs `/plugin install project-memory@octonify`
once, which works immediately because the marketplace is already registered.

## Plugins

| Plugin | What it does | Install |
|---|---|---|
| `project-memory` | Scaffolds and audits a git-native long-term project memory structure: `CLAUDE.md`, arc42 knowledge docs, ADRs, Conventional Commits and drift checks. Skills: `/project-memory:init`, `/project-memory:audit`. | `/plugin install project-memory@octonify` |

## Status of `project-memory`

**Experimental, version `0.2.0`.** The documentation architecture it installs is assembled from
published conventions — arc42, Nygard ADRs, Conventional Commits — but the way they are combined
here, along with the numeric budgets, the confidence markers, the `covers_paths` drift check and
the three-tier durability model, is a proposal that has not been validated on a real project over
time. The version number says so on purpose.

The shipped scripts have been executed against a scratch repository, against this one, and on
Linux (GNU bash 5.2.21, git 2.43.0, with `jq` present and absent). The architecture they enforce
has not been through a year of maintenance.

## Releasing

Per plugin, in this order:

1. Change the plugin under `plugins/<name>/`.
2. Bump `version` in `plugins/<name>/.claude-plugin/plugin.json`. **Users receive an update only
   when this string changes.**
3. Add a dated entry to `plugins/<name>/CHANGELOG.md`.
4. Commit with the plugin as the scope: `feat(<name>): ...`.
5. Tag, annotated and scoped: `claude plugin tag ./plugins/<name> -m "..."`, which produces
   `<name>--v<version>` and checks that the manifests agree. Never a bare `v<version>`.
6. `git push --follow-tags`.

Working notes for this repository are in [`CLAUDE.md`](CLAUDE.md); the reasoning behind its shape
is in [`docs/decisions/`](docs/decisions/).

## Further reading

The design `project-memory` implements, and the reasoning behind every default it chooses:
[`plugins/project-memory/reference/architecture.md`](plugins/project-memory/reference/architecture.md).

## License

MIT. See [LICENSE](LICENSE).
