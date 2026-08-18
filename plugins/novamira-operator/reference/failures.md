# Known Novamira failure modes

Each entry is a failure verified against a live site. Several report success
while losing your work.

## Silent, reports success

**Design system: half the guidance vanishes.**
Symptom: `save-design` returns `readiness.ready: true`, but `guidance.dos`
comes back empty.
Cause: Do/Don't bullets are classified by **literal prefix**, not by section
position. A bullet reading "Use the accent color sparingly" is discarded. Only
bullets beginning with the word "Do" are captured. Don'ts survive because
"Do not…" happens to start with "Do".
Fix: begin every Do bullet with "Do". Verify `guidance.dos` in the response
before treating the design as saved.

**Design system: tokens silently unparsed.**
Symptom: colors come back marked `inferred`; typography, spacing, rounding,
components and dials are absent.
Cause: the document used markdown headings instead of YAML front matter.
Fix: see `design-system.md`. Always check `token_sources`, not just
`readiness` — a document can be `ready: true` on guessed colors.

**Skill written, then not invocable.**
Symptom: `skill-write` returns `success: true` and `action: "created"`, but no
slash command appears.
Cause: MCP prompts are fetched once, at connection time. A skill created
during a session is invisible until the client reconnects. Nothing in
Novamira signals this.
Fix: tell the user to reconnect. The command will be
`/<server>:novamira-skill-prompt-<slug>` — the bare slug will not match. The
staleness runs both ways: a deleted skill's command lingers until reconnect.

**Disabled skill looks deleted.**
Symptom: `skill-get` returns `{"found": false}` for a skill you know exists.
Cause: disabled and deleted are indistinguishable through the read path. There
is no `enabled` field in the response and no `skill-list` ability.
Fix: do not recreate it. Only wp-admin can tell you, and recreating may
produce a duplicate under a renamed slug.

## Fails loudly, but for a non-obvious reason

**`agent-context` rejected on Visual.**
Error: `Ability "novamira/agent-context" does not define an input schema
required to validate the provided input.`
Cause: its input schema serializes as an empty JSON array, which the Visual
bridge's validator rejects. Exactly one ability is affected. The superficially
similar nested `properties: []` on other abilities is harmless.
Fix: on Visual, use `workspace_discover_backend_tools` with
`include_instructions: true` instead.

**WP-CLI unavailable.**
Error: `Process execution (proc_open or exec) is disabled in PHP
configuration.`
Cause: host configuration, not Novamira and not permissions. Common on shared
hosting. Both the synchronous and asynchronous paths fail identically.
Fix: there is none from the agent side. Do the work through `execute-php` or
the relevant abilities instead, and tell the user why.

**Cloud AI clients blocked at connection time.**
Symptom: OAuth from a cloud client is challenged or refused, while the same
site connects fine from a locally-run client.
Cause: some hosts classify server-to-server requests from provider
infrastructure as bot traffic. Novamira detects several such hosts and warns.
Fix: connect from a locally-run client, or use an Application Password with
direct HTTP transport. This is about where the request originates, not about
the auth method itself.

## Things that will get you into trouble

- Modifying, updating, deactivating or deleting the Novamira plugin, or
  revoking the credentials of the connected user. You are cutting your own
  connection.
- Writing `post_content` or block markup through `execute-php`. Use the
  Gutenberg abilities on REST, or the editor page tools on Visual.
- Registering post types, taxonomies or fields in PHP when a data-modeling
  plugin is active. The site's own instructions cover this; follow them.
- Treating `check-design`'s `ok: true` as "all rules passed". Six structural
  checks never run. See `design-system.md`.
