# The Novamira design system

Seven abilities. Storage is a custom post type. One design is active per site.

## DESIGN.md is YAML front matter

Not markdown headings. Headings parse partially and dishonestly: colors are
captured but flagged `inferred`, and typography, spacing, rounding, components
and dials are dropped with no error. The prose body below the front matter is
rationale only — nothing is parsed from it.

The built-in `novamira-design` skill on the site documents the full contract.
Load it with `novamira/skill-get` before authoring a design. Do not guess the
format, and do not rely on this file for the field names — it tells you the
gates and the traps, the site's own skill tells you the schema.

## Five roles gate activation

A document is not `ready`, and cannot be activated, without all five:

`colors.bg`, `colors.ink`, `colors.accent`, `typography.heading`,
`typography.body`

Warning only, does not block: spacing tokens, corner-radius tokens, component
treatments, compositional dials. Omitted dials default to `variance 0.8,
density 0.4, motion 0.5`.

## Check `token_sources`, not just `readiness`

`token_sources` reports, per category, one of `explicit`, `inferred`,
`missing`. **A document can be `ready: true` with colors marked `inferred`** —
meaning the server guessed them from prose. That is the honest signal of how
much was actually understood. Read it every time.

## Other verified behaviour

- Tokens are returned **without normalization**. Hex, font and length strings
  come back exactly as written.
- The token set is **open**. Extra keys beyond the five required roles are
  accepted and returned.
- `get-active-design` returns `content`: the raw DESIGN.md, byte-identical to
  what was sent. Unlike skills, the design system does not rewrite your
  document.
- An incomplete document saves as a draft, is listed in the library with
  `ready: false`, and never overwrites the active design.
- `delete-design` on the active design leaves the site with none, and reports
  `was_active: true`.

## `check-design` is a linter, and an honest one

Returns `{ok, violations[{rule, severity, message, evidence}], checked[],
not_checked[]}`. Severity is `fail` or `warn`. `evidence` names the exact
offending values — the hex codes, the font, the filler words, the em-dash
count — so violations are actionable without guessing.

**Nine string-based checks run:** `em-dash`, `ai-purple`, `inter-font`,
`warm-craft-palette`, `filler-copy`, `generic-names`, `font-off-palette`,
`color-off-palette`, `design-dont`.

**Six structural checks never run:** `hero-in-viewport`, `centered-mega-hero`,
`three-equal-cards`, `eyebrow-overuse`, `zigzag-cap`,
`section-layout-repetition`.

`not_checked` is reported on every call, pass or fail. **`ok: true` means the
string-based subset found nothing — not that the output is good.** The six
structural rules are exactly the ones about layout monotony, and they are your
responsibility to check by reading the composition.

Run `check-design` before finalizing any visual output, and fix every `fail`.
