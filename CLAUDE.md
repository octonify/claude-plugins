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
2. **Git tags are scoped per plugin, with a double dash:** `project-memory--v0.2.0`, never a bare
   `v0.2.0` and never a single dash. One repository holds several independently versioned plugins,
   so a bare semantic version does not say what it released. `--` is the separator `claude plugin
   tag` produces, and it cannot occur inside a kebab-case plugin name, so the tag parses in one
   direction only. Always annotated.
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
10. **A shipped script may not discard an error silently.** Every occurrence of `|| true`,
    `|| echo <value>`, `2>/dev/null`, `>/dev/null 2>&1`, and `[ -z "$x" ] && continue|exit 0`
    carries a comment on the line above saying why silence is correct there. An uncommented
    occurrence is a defect. The gate runs over every shipped asset whose first line is a shebang,
    so extensionless hooks are covered:

    ```bash
    grep -nE '\|\|[[:space:]]*(true|echo)|2>/dev/null|>/dev/null[[:space:]]+2>&1|^\s*\[ -z .* \]\s*&&' \
      $(awk 'FNR==1 && /^#!/ {print FILENAME}' plugins/*/assets/*)
    ```

    Three known limits: it covers only shell; it cannot see the same defect in a skill file, where
    an instruction lets an agent conclude "not applicable" when it means "I could not tell"; and it
    finds only syntactic shapes — a script that asserts a precondition it never verifies, such as
    assuming it runs from the repository root, contains nothing to grep for.
11. **Accepted decision records in `docs/decisions/` are immutable.** The single exception: a
    dated, append-only note under a trailing `## Notes` heading, and only to record a later
    observation or to correct a claim in Context or Consequences that turned out to be false. A
    note may never change the Decision — a changed Decision still requires a superseding record,
    with no exception — and nothing above the `## Notes` heading is ever edited. Where
    `protect-files.sh` is installed it blocks the whole `docs/decisions/` directory and cannot
    tell a note from an edit; hitting that block while writing a legitimate note is expected, and
    overriding it is a conscious act, not a sign the hook is broken.

## Adding a plugin

Exactly three things change:

1. A new directory `plugins/<name>/` containing `.claude-plugin/plugin.json`, `CHANGELOG.md` and
   at least one `skills/<skill>/SKILL.md`.
2. A new entry in the `plugins` array of `.claude-plugin/marketplace.json`, with `name`, `source`
   (`./plugins/<name>`) and `description`.
3. A new row in the README plugin table.

The GitHub repository description is **not** one of them. Do not touch it as part of adding a
plugin.

## Branches

`main` is the release channel: it is the default branch, so it is what users install from, and it
holds only released state. Work happens on `next`. `main` moves only at release, by merging
`next` into it. See `docs/decisions/0008-default-branch-is-the-release-channel.md`.

## Release procedure

For a change to plugin `<name>`:

1. Make the change under `plugins/<name>/`, on `next`.
2. Bump `version` in `plugins/<name>/.claude-plugin/plugin.json`. Semantic versioning. A plugin
   whose design has not been validated in real use stays below `1.0.0`.
3. Convert the changelog under `plugins/<name>/`. This is a conversion, not an addition, and it
   has four parts: turn `[Unreleased]` into the version heading with today's date; replace the
   unreleased-state paragraph, which becomes false inside a released block; open a fresh empty
   `[Unreleased]` above it; add the version's link reference at the bottom. Then retarget any
   pointer elsewhere in the file that says "Unreleased". Round 5 hit all four and the procedure
   had warned of none.
4. Commit, scoped: `git commit -m "feat(<name>): ..."`.
5. Merge into `main` with `git merge --ff-only next`. This is the only way `main` moves.
   Fast-forward only: the tag is the release marker (ADR 0005), and a merge commit would add a
   second marker carrying no information the tag does not.
6. Tag from the plugin directory:
   `claude plugin tag ./plugins/<name> -m "<what changed, in one or two sentences>"`. It creates
   `<name>--v<version>` annotated. Its version-agreement check cannot fire in this repository: it
   refuses only when `plugin.json` and the marketplace entry both carry a `version` and they
   disagree, and hard rule 1 forbids a marketplace `version` — see the note in ADR 0005. Do not
   add a marketplace `version` to make the check real; that trades a vacuous check for the
   two-pinning-fields disagreement the hard rule exists to prevent. The hand-written equivalent
   is `git tag -a <name>--v<version> -m "..."`.
7. Push from `main`: `git push --follow-tags`. Then push `next` too — the merge left it behind
   `origin/main` otherwise, which is backwards for this branch model.
8. Delivery to an installed user is not automatic. As observed once, on one CLI version, on one
   machine: `claude plugin marketplace update <marketplace>` refreshes the catalog and moves
   nothing; the installed plugin stays on its old version until
   `claude plugin update <plugin>@<marketplace>`; and a session restart is required to apply it.

Steps 2 and 3 are the ones that get skipped. If a change is worth pushing, it is worth a version.

## Where to look

| I need... | Read |
|---|---|
| why one repository holds every plugin | `docs/decisions/0001-single-repository-marketplace.md` |
| why the marketplace is called `octonify` | `docs/decisions/0002-generic-marketplace-name.md` |
| why versions are per plugin | `docs/decisions/0003-independent-plugin-versions.md` |
| why tags carry a plugin prefix | `docs/decisions/0004-scoped-git-tags.md` (superseded) |
| why the tag separator is `--` | `docs/decisions/0005-double-dash-tag-convention.md` |
| why a check exits 2 rather than passing quietly | `docs/decisions/0006-checks-fail-loudly-when-they-cannot-run.md` |
| why the commit hook is not enforcement | `docs/decisions/0007-local-git-hooks-are-feedback-not-enforcement.md` |
| why work happens on `next`, not `main` | `docs/decisions/0008-default-branch-is-the-release-channel.md` |
| what `project-memory` installs, and why | `plugins/project-memory/reference/architecture.md` |
| the source material `project-memory` was distilled from | `project-memory-structure-template.md` |
| what this repository does not know | `docs/knowledge/07-open-questions.md` |

## Rounds with the planning layer

Work sometimes arrives as numbered request rounds from a planning layer, exchanged through the
gitignored `agent-exchange/` directory. Requests and reports are channel content and stay local,
never on GitHub; these rules are process and live here. They hold unless a request explicitly
overrides one:

1. One round, one theme, one plugin.
2. Never bump `version`, never tag, never push, unless the request says so explicitly.
3. The report is a file: `report.md` in the round directory, not only terminal output.
4. Attach the complete current text of every file the round touched, prefixed `attach-`.
5. Quote actual commands and actual output for every test. "Tested and working" is not a report.
6. "What I chose not to do, and why" is a required section.
7. Anything found outside the round's scope is reported, not fixed.
8. Never ship a CI workflow file.
9. Propose promotion before the round closes; deciding it is the planning layer's call.
10. Mark inference as inference and assumption as assumption.

Known defects go by audience: a user-facing defect in a shipped asset goes in that plugin's
`CHANGELOG.md` under `## Known defects`; a repository-side defect with no user exposure stays in
the round channel until there are enough to justify a file.

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
