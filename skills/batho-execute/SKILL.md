---
name: batho-execute
description: >
  Execute one or more Batho specs: build a graph-grounded multi-task implementation plan
  (plan_<name>.md) from the spec, then implement task-by-task with pre-edit symbol grounding
  and post-edit delta verification. USE when the user says "execute spec <name/number>",
  "implement the spec", "proceed with the plan", or approves execution at the end of
  batho-specs. Handles single- and multi-spec execution with dependency ordering.
  DO NOT USE for writing specs (batho-specs) or reviewing them (batho-review).
metadata:
  version: 1.0.0
---

# batho-execute — Spec-Driven Planning + Implementation

You execute grounded specs from `batho-specs/NN-<name>/`. Two phases:
**(1) plan** — re-ground the spec in the current graph and write `plan_<name>.md`
into the same folder; **(2) implement** — execute tasks with pre-edit grounding
and post-edit delta verification. Finish by offering a review (batho-review).

## Phase 1 — Load & re-anchor

1. Resolve requested spec(s): `batho-specs/NN-<name>/specs_<name>.md` (user may
   name one, several, or "latest"). Missing spec → list available folders, stop.
2. Freshness gate: `batho_status`; stale → CLI `batho patch` → re-check.
3. Re-anchor every §3 entity: `get_entity(entity_id)`. If an anchor no longer
   resolves, re-find via `search_entities` and record the re-anchor in the plan.
   Unresolvable anchors → task marked `NEEDS-RECON` (back to batho-specs).

## Phase 2 — Plan (graph-grounded, multi-task)

4. For each §4 Proposed Change: anchor via `get_entity`; impact via
   `graph_query(relation_direction="incoming")` (+ `trace_path(max_depth=3)`
   when direct fan-in >5).
5. Risk tier: LOW ≤5 incoming, no boundary crossing · MEDIUM 6–20 or one
   `STACK_BOUNDARY` crossing · HIGH >20 or anchor has `IMPLEMENTS`/`OVERRIDES`
   edges (polymorphic blast radius).
6. Order tasks dependencies-first (callees/providers before dependents).
   `[P]` parallel iff impact zones share no file AND `trace_path` between
   anchors returns no path.
7. **Write `plan_<name>.md`** into the spec's folder (template:
   `references/plan-template.md`).

**Gate**: every caller of a renamed/changed symbol is covered by a task before
implementation starts. A task with no impact zone is `NEEDS-RECON`, never guessed.

## Phase 3 — Implement

8. Per task: `get_entity(entity_id, include_source=true)` (exact current
   signature) → edit with normal tools → CLI `batho patch` →
   `get_delta(file_path=<touched>)` → confirm added/modified match intent;
   unexpected removals = stop and explain.
9. Tick the task's checkbox in `plan_<name>.md` as it completes. Re-index after
   each task (not each edit) unless the task spans files.

**Gates**: no edit before grounding · no "done" before delta verification ·
multi-spec runs execute in dependency order (shared anchors serialize).

## Phase 4 — Completion

10. All tasks verified → **ask the user**: "review the implementation?" —
    yes → invoke **batho-review** for this spec; no → done.

## Multi-spec execution

- Topo-sort specs by shared anchors (`trace_path` between anchors).
- Independent specs may interleave; never parallel-edit the same file.
- One `plan_<name>.md` per spec folder — never merge specs into one plan.

## Token budgets

- `get_entity(include_source=true)` only for the current task's edit set.
- `graph_query(limit=50)` per hop; `trace_path(max_depth=3)` default for impact.
- Patch after each task, not each edit (state the choice in the plan).

## References (load on demand)

- `references/plan-template.md` — plan_<name>.md template
- `references/workflows.md` — worked example (2-change spec → plan → verify)
- `references/fallbacks.md` — anchor drift, Tier-3 disabled, zero results

## Hard rules

1. The spec (`specs_<name>.md`) is the source of truth — implement IT, not your
   memory of the conversation.
2. Write only inside the spec's own `batho-specs/NN-<name>/` folder.
3. Never skip the pre-edit grounding, even for "small" changes.
4. Never claim done without `get_delta` verification per task.
5. Always offer review at the end; never auto-invoke batho-review.
