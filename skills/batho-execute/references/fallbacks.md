# batho-execute — Fallbacks

## Anchor drift (spec entity no longer resolves)

1. `search_entities(query=<name>)` → `get_entity` to re-identify.
2. Record the re-anchor in the plan's Re-anchors table (spec ID → new ID).
3. If the symbol was deleted since the spec was written → task `NEEDS-RECON`;
   surface to the user before improvising.

## Tier-3 MCP tools disabled (default)

- `batho_patch` absent from tool list → CLI: `batho patch --root <path>`.
- Confirm the patch landed: `batho_status` generation advanced; then `get_delta`.
- Never claim verification without an advanced generation.

## Zero-result queries mid-execution

- `get_entity` miss on an anchor → `search_entities` with shorter query →
  still nothing → grep the definition → `batho patch` → retry the graph query.
- `trace_path` returns no path → report "no structural path" (never invent one);
  treat the pair as independent for `[P]` marking.

## Ambiguous names mid-execution

`get_entity` returns multiple candidates → stop, show the user, record the
chosen `entity_id` in the plan. Never guess.

## Uncommitted / partially-edited working tree

Patch before planning (Phase 1) so the plan anchors match the tree. If edits
land mid-run from another actor, re-run the freshness gate before the next task.
