# batho-execute — Worked Example & Gate Details

## Worked example (abridged): rename + signature change

Spec `batho-specs/03-rename-loader/specs_rename-loader.md` proposes:
- R1: rename `load_config` → `load_settings` (entity `ent_a1`)
- R2: add `validate` param to `load_config`'s replacement (signature change)

### Plan phase (tool sequence)

1. `batho_status` → generation 948, fresh.
2. `get_entity(entity_id="ent_a1")` → resolves; incoming: 7 CALLS edges.
3. `graph_query(target_id="ent_a1", relation_direction="incoming",
   relation_types=["CALLS","IMPORTS"])` → 7 callers across 4 files.
4. `trace_path(source="ent_a1", max_depth=3, relation_direction="outgoing")`
   → no transitive surprises beyond direct callers.
5. Risk: 7 incoming, no boundary crossing → MEDIUM.
6. Tasks: T1 update definition (callees first), T2–T5 update 4 caller files,
   T6 update tests. Callers 2–5 share no files with T1's zone → `[P]` pairs.
7. Write `plan_rename-loader.md` with the table + verification contracts.

### Implement phase (per task)

```
get_entity(ent_a1, include_source=true)   # exact current signature
  → edit loader.py (rename + signature)
  → $ batho patch --root <repo>            # CLI (Tier-3 MCP absent)
  → get_delta(file_path="src/config/loader.py")
  → delta shows modified: load_config→load_settings ✓  → tick task 1
```

### Gate checks

- **Caller coverage**: plan lists 7 callers; grep-after-edit is forbidden —
  coverage comes from `graph_query(incoming)` at plan time.
- **Delta verification**: `get_delta` after each patch; `artifact_generation`
  must advance; a task whose delta shows unexpected `removed` entries stops
  the run.

## Multi-spec ordering example

Specs 04 (adds helper in `util.py`) and 05 (renames a caller of that helper):
`trace_path` between anchors returns a path → serialize (05 after 05's
dependency lands). Independent specs (no path, no shared files) may interleave.

## Failure drills

| Situation | Response |
|---|---|
| Anchor unresolvable at load | `search_entities` re-find → record re-anchor; unresolvable → `NEEDS-RECON` |
| `batho_patch` not in tool list | CLI `batho patch --root <path>`; confirm generation advanced via `batho_status` |
| Delta shows unexpected removal | STOP. Explain to user; do not proceed to next task |
| Edit target file not in spec's blast radius | Stop — the change exceeds the spec; report to user |
