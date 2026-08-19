# Changelog — novamira-operator

All notable changes to this plugin. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The `version` field in `.claude-plugin/plugin.json` must be bumped in the same commit as any entry
below. Without that bump, no installed user receives the change.

## [Unreleased]

## [0.1.0] — 2026-08-19

First release. Every behavioural claim in this plugin was verified against a live Novamira
installation rather than taken from documentation; see the Status section in the repository
README for what that evidence base does and does not cover.

### Added

- `operate` skill: what the site's own connection instructions do not say. How to tell the REST
  transport from the Visual one from the tool names alone, without spending a call; what each
  transport can and cannot reach; why discovery is not a capability contract; and why the
  permission layer cannot distinguish a safe ability from a destructive one, so the agent has to
  state the risk itself.
- `reference/failures.md`: Novamira failure modes verified against a live site, split into the
  ones that report success while losing work, the ones that fail loudly for a non-obvious reason,
  and the actions that cut your own connection.
- `reference/design-system.md`: the DESIGN.md contract — YAML front matter, not headings — the
  five roles that gate activation, why `token_sources` is the honest signal and `readiness` is
  not, and the six structural `check-design` rules that never run.
- `reference/skills-api.md`: the four skill abilities, the three server-side mutations
  `skill-write` performs on what you send, the `on_conflict` modes and which of them are
  untested, and why a skill you just created is not invocable until the client reconnects.

[0.1.0]: https://github.com/octonify/claude-plugins/releases/tag/novamira-operator--v0.1.0
