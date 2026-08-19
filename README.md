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
| `novamira-operator` | Operating knowledge for driving a WordPress site through the Novamira MCP plugin: transport differences, the `DESIGN.md` contract, skill authoring semantics, and failure modes that report success. Skill: `/novamira-operator:operate`. | `/plugin install novamira-operator@octonify` |

## Status

### `project-memory`

**Experimental, version `0.3.0`.** The documentation architecture it installs is assembled from
published conventions — arc42, Nygard ADRs, Conventional Commits — but the way they are combined
here, along with the numeric budgets, the confidence markers, the `covers_paths` drift check and
the three-tier durability model, is a proposal that has not been validated on a real project over
time. The version number says so on purpose.

The shipped scripts have been executed against a scratch repository, against this one, and on
Linux (GNU bash 5.2.21, git 2.43.0, with `jq` present and absent). The architecture they enforce
has not been through a year of maintenance.

### `novamira-operator`

**Experimental, version `0.1.0`.** Unlike a plugin assembled from published conventions, every
behavioural claim here was verified by calling a live Novamira installation and reading what came
back: the transport differences, the `DESIGN.md` contract, the skill-authoring semantics, and each
failure mode. Several of those failures report success while losing your work, which is why they
are written down.

The evidence base is real and narrow. One WordPress site, on one host, on one Novamira version,
with Novamira Pro active and a specific theme and page builder installed. Behaviour that is
structural — what each transport reaches, what the design parser accepts, what `skill-write` does
to what you send — should hold anywhere. Anything that depends on the host, the installed plugins,
or a Novamira release later than the one tested may not. The plugin deliberately ships no ability
inventory for that reason: discovery returns it in one call, always current, and a bundled copy
would go stale within weeks.

The skill's trigger description has not been tuned against real use. It errs toward firing, on the
reasoning that a false positive costs a few hundred tokens and a false negative costs the whole
point of the plugin.

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
