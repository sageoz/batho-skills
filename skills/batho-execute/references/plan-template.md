# Plan Template — plan_<name>.md (batho-execute output)

Written into the spec's own folder: `batho-specs/NN-<name>/plan_<name>.md`.

```markdown
# Plan: <Feature / Task Name>

**Spec**: `specs_<name>.md` (Spec ID <NN>) | **Status**: planned | in-progress | done
**Created**: <date> | **Batho artifact**: generation <N> at planning time
**Spec anchors re-verified**: <yes/no — count re-anchored>

## Tasks

| ID | Task | Target entity_ids | Files | Risk | Tests | Status |
|----|------|-------------------|-------|------|-------|--------|
| 1  | <change> | `ent_...` | `path` | LOW/MED/HIGH | `tests/...` | ☐ |
| 2 | [P] <parallel task> | ... | ... | ... | ... | ... |

Order: 1 → 2 → 3 (dependencies first; [P] = parallelizable — disjoint impact zones)

## Execution Order & Dependencies
1 → 2 → 3; 2 ∥ 3 (no shared files, no structural path between anchors)

## Re-anchors (spec written at generation N, executing at generation M)
| Spec entity_id | Status | Re-anchored to |
|---|---|---|

## Verification Log
| Task | get_delta result | artifact_generation | Result |
|---|---|---|---|
| 1 | nodes_modified: 2 (expected) | 951 | ✓ |

## Deviations
- <any deviation from the spec, with reason>
```

## Filling guide

- **Target entity_ids**: from the spec §3/§4 — re-verified via `get_entity` at plan time.
- **Risk**: LOW/MEDIUM/HIGH per batho-execute SKILL.md thresholds.
- **Tests**: files whose imports touch the impact zone (`file_connectivity`).
- **Status**: `☐` planned → `◐` in-progress → `☑` verified (delta-checked).
- **Verification Log**: one row per task — what `get_delta` showed, generation after patch.
- A task is DONE only when its delta row matches intent. Mismatch → investigate
  before moving on; never mark verified on a failed delta check.
