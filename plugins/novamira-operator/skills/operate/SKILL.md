---
name: operate
description: Operating knowledge for working on a WordPress site through the Novamira plugin — transport differences, the DESIGN.md contract, skill authoring semantics, and known failure modes that waste turns. Use whenever Novamira is connected or mentioned, and when building, editing, or auditing a WordPress site through an MCP connection to it.
---

# Working through Novamira

Novamira turns a WordPress site into an MCP server. The site sends you its own
instructions on connection: environment, installed plugins, active theme,
available skills. **Read and follow those.** This document covers only what
that block does not tell you.

## First: which transport are you on

The tool names tell you, at zero cost. Do not call anything to find out.

| Tools you can see | Transport |
|---|---|
| `mcp-adapter-discover-abilities`, `-get-ability-info`, `-execute-ability` | **REST** |
| `workspace_status`, `workspace_connection_info`, `workspace_request` | **Visual** |

This determines what is possible. It is not a preference.

**If you cannot tell — neither set matches, or both appear — say so and stop.**
Do not proceed on a guess and do not silently pick one. Everything below
branches on this answer, so a wrong guess produces confidently wrong work.
Name what you can see and ask.

**On REST:** call `novamira/agent-context` once. It returns the environment,
the server's feature flags, and a structured `skills` array with slug,
description and source. That is your orientation, in one call.

**On Visual:** `agent-context` is broken — its input schema is an empty array
and the bridge rejects it. Use `workspace_discover_backend_tools` with
`include_instructions: true` instead; the instructions string carries the same
environment and skill roster.

## What each transport can and cannot do

| | REST | Visual |
|---|---|---|
| Elementor abilities | yes, headless | **none** |
| Gutenberg abilities and the pending-change queue | yes | **none** |
| Editor page tools | none | yes, only while an editor is open |
| Skills exposed as invocable prompts | yes | **no** |
| Per-ability confirmation enforced | **no** | yes, in wp-admin |

Visual is a strict subset of REST at the ability layer and withholds the
Elementor and Gutenberg surfaces on purpose, because it drives them through a
live editor instead. Novamira filters the advertised skill roster to match, so
on Visual you will not even be told about skills you could not execute.

**Never conclude "this is not possible" from one transport.** Say which
transport you are on and what it excludes.

**On Visual, page and builder content does not go through abilities at all.**
Open the page in its editor first, then use the editor page tools that appear.
Never write `post_content` or block markup through `execute-php`.

## Discovery is not a capability contract

An ability appearing in discovery, with a complete schema and annotations,
does **not** mean it can run. Verified case: both WP-CLI abilities are
advertised on every transport and fail on any host where PHP has `proc_open`
and `exec` disabled — which includes common shared hosting.

Before planning around WP-CLI, or any ability whose work happens outside PHP,
run the cheapest possible form of it and read the error. Do not assume.

## Approval does not distinguish safe from dangerous

Every ability is invoked through one tool — `mcp-adapter-execute-ability` on
REST — with the ability name as a string argument. The per-ability `readonly`
and `destructive` annotations live in a different tool's response and never
reach the approval layer. There is no `requires_confirmation` field on REST at
all; it exists only on the Visual bridge.

Practical consequence: once the user allows that tool, `execute-php`,
`delete-file`, `delete-post` and `create-admin-access-link` all run without
further prompting.

**So state the risk yourself.** Before anything destructive, say plainly what
will change and what cannot be undone. The permission system will not do it
for you. The annotations under-warn even where they exist: `save-design` is
marked `destructive: false` while overwriting site state, and
`create-admin-access-link` is marked `destructive: false` while minting an
admin session.

## Before you go further

- Writing or editing a design system, or checking visual output: read
  `${CLAUDE_PLUGIN_ROOT}/reference/design-system.md` first. The document
  format is not what it looks like, and getting it wrong fails silently.
- Creating, editing, or deleting a Novamira skill: read
  `${CLAUDE_PLUGIN_ROOT}/reference/skills-api.md` first.
- Anything behaving unexpectedly: check
  `${CLAUDE_PLUGIN_ROOT}/reference/failures.md` before debugging. Several
  Novamira failure modes report success.
