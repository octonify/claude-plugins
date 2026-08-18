# Authoring Novamira skills

Four abilities: `skill-get`, `skill-write`, `skill-edit`, `skill-delete`.
There is no `skill-list` — on REST, `agent-context` returns a structured
`skills` array instead; on Visual, the instructions block is the only listing.

Novamira skills are **flat single markdown documents**. No bundled scripts, no
reference files, no companion assets. Helper code goes in a sandbox file and
is referenced by path from the body.

## `skill-write` changes what you send

Required: `title`, `description`, `content`. Returns `{success, slug, action}`
with `action` ∈ `created` / `updated` / `renamed`. The slug is returned
directly — do not infer it.

Three server-side mutations, all verified:

- **The human title is discarded.** The slug is the title lowercased with
  spaces hyphenated, and no field anywhere preserves the original. Choose a
  title that survives slugification.
- **`content` is rewritten**, with YAML front matter prepended carrying `name`
  (the slug), `description`, `enable_prompt`, `enable_agentic`. Your body
  survives byte-identical below it. Do not write your own front matter.
- `source: "user-cpt"` is added, which is how user skills are identified.

## `on_conflict`

- `fail` — plain error, no envelope.
- `rename` — appends a numeric suffix and **leaves the original in place**, so
  a conflict test creates a second skill. Clean up both.
- `replace` — untested. Assume it overwrites.
- **Omitted** — untested. The ability is described as "create or update" and
  `action` includes `updated`, so assume the default overwrites. If you do not
  intend to overwrite, pass `on_conflict: "fail"` explicitly.

## `skill-edit`

Returns `{success, slug, changed_fields[]}`. Partial patching genuinely
preserves unspecified fields. Editing `description` regenerates the front
matter inside `content` to match. `enabled` can only be set here — it is not a
`skill-write` parameter.

**Setting `enabled: false` makes the skill unreadable.** `skill-get` then
returns `{"found": false}`, identical to a deleted skill. There is no way back
through the ability layer. Prefer deleting to disabling unless the user asked
specifically to disable.

## Prompts

`enable_prompt: true` exposes the skill as an invocable command **on REST
only**. Visual does not advertise prompt capability at all.

The command name is `/<server>:novamira-skill-prompt-<slug>`.

**The prompt list is fetched once, at connection time.** A skill you create is
not invocable until the client reconnects, and a skill you delete stays
visible until then. `skill-write` returns the same `success: true` either way.
If the user needs to invoke a skill you just created, tell them to reconnect.

## Writing a good one

The description is the trigger and the only field read at session start —
write it so someone who has not seen the body knows when it applies. Keep the
body well under 5,000 words; most fit in 200 to 800. The built-in
`skill-creator` skill on the site covers authoring guidance; load it rather
than duplicating its advice here.
