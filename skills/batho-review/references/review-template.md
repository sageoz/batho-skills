# Review Template — review_<name>.md

Written into the spec's own folder: `batho-specs/NN-<name>/review_<name>.md`.
Append-only: new runs add a dated section; earlier verdicts stay for history.

```markdown
# Review: <Feature / Task Name>

**Spec**: `specs_<name>.md` | **Reviewed**: <date>
**Batho artifact**: generation <N> | **Run**: <run_uuid>
**Verdict**: PASS | GAPS

## 1. Criterion Verification
| # | Acceptance criterion (spec §8) | Implementing entity | Evidence | Status |
|---|--------------------------------|---------------------|----------|--------|
| 1 | <criterion> | `ent_...` @ `path:line` | <graph fact / delta row> | PASS |

## 2. Structural Findings
- Dangling references: <none | list — removed/renamed symbols still referenced>
- Orphans introduced: <none | list (zero incoming, not entry points)>
- Blast-radius delta: <new dependents acquired vs spec §5, if any>
- Boundary crossings: <none | list>

## 3. Gap Tasks
| # | Gap | Fix (graph-cited) | Blocks convergence |
|---|-----|-------------------|--------------------|

## 4. Provenance
- Batho artifact generation: <N> | Run: <run_uuid>
- Reviewed by: batho-review skill v1 | <date>
```

## Verdict rules

- **PASS** requires: every criterion PASS + zero dangling references + no
  out-of-spec structural changes.
- Dangling references or out-of-spec changes → GAPS + concrete gap tasks
  (each citing the entity/file to fix).
- `renamed` coverage: `get_delta(change_kind="renamed")` must show the spec's
  renamed entities; missing renames are GAPS.
