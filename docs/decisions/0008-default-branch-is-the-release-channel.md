# 0008. The default branch is the release channel

**Status:** accepted
**Date:** 2026-08-16

## Context

A marketplace added from GitHub without an explicit `ref` reads the repository's default branch.
Whatever `main` holds is what a new installer receives, immediately, commit by commit. The
`version` field in `plugin.json` pins updates for *installed* users — an unchanged version string
means no installed user receives new content — but it does not gate what a *new* installer gets:
they get the default branch as it stands, labelled with whatever version it declares.

Those two facts interact badly with developing on the default branch. Plugin versions determine
cache paths on the user's machine, so pushing changed content under an unchanged version means two
installations can report the same version while holding different files. There is no way to tell
them apart by version string, which is the only identity a plugin install has.

The alternative considered was pinning the plugin itself to a release tag. The plugin's `source`
in `marketplace.json` is the relative path `./plugins/project-memory`, resolved inside whatever
checkout the marketplace was loaded from; a path source cannot carry its own `ref`. Pinning would
mean converting the source to a `git-subdir` object — a mechanism neither tested nor needed yet.

## Decision

`main` holds only released state and is what users install from. Development happens on `next`.
`main` moves only at release, by merging `next` into it. The plugin `source` stays a relative
path; nothing in `marketplace.json` changes.

## Consequences

- A release becomes a merge to `main` plus a tag, instead of only a tag.
- The `git-subdir` source form remains available later if per-plugin release channels are ever
  needed; adopting `next` now does not foreclose it.
- `origin/main` now exists and differs from `HEAD` on `next`, so this repository is finally a real
  test case for its own drift check, which until now had only ever run in a repository with one
  branch and no divergence.
