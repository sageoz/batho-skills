---
name: batho-specs
description: >
  Research, plan, and write a graph-grounded specification for a feature, code change, or
  workspace task. USE when the user describes something to build or change ("add X", "refactor
  Y", "fix Z", "write a spec for..."), during /speckit.specify or Kiro requirements phases, or
  when asked to spec out a task against this repo. Grounds every statement in Batho graph
  entities and relationships, computes blast radius and coverage, and stores the spec in
  batho-specs/NN-<name>/specs_<name>.md after user approval. DO NOT USE to implement the spec
  (batho-execute does that), for exact-string search, or when no Batho graph exists.
metadata:
  version: 1.0.0
---

# batho-specs — Research → Planning → Grounded Specification

You are the specification author. Produce a **grounded truth** document a coding
agent can implement smoothly with Batho MCP tools. Every claim about the current
system cites Batho graph entities and relationships (`entity_id` + `file:line`).

Assume the `batho` skill ran (artifact exists and is fresh). If `batho_status`
shows otherwise, do its lifecycle steps first (build/patch) before researching.

## Phase R — Research (recursive until closure)

1. `batho_status` → artifact present and fresh? (stale → `batho patch`, CLI
   default). Record `artifact_generation`.
2. Frame the area: `graph_overview(response_format="summary")`, or
   `get_file_graph(file_path=<entry file>)` if the feature names a module.
3. Locate the touched subsystem: `search_entities(query=<domain nouns>)` →
   `graph_query(file_path=<area>, relation_direction="both")`.
4. **Recursive deepening loop** — for each entity in scope: `get_entity`
   (all incoming/outgoing relationships); follow `CALLS`/`USES`/`IMPORTS`/
   `INHERITS`/`IMPLEMENTS`/`OVERRIDES` edges one hop further while new entities
   keep appearing. Stop when a full pass adds nothing new (closure) or the cap
   is hit (3 rounds / 40 entities — log the truncation).
5. Reuse check: `search_entities` per concept name; flag near-duplicates.
6. Boundary check: `file_connectivity(file_path, direction="both")` on touched
   files; note `STACK_BOUNDARY` crossings and external/stdlib edges.

**Gate G1** — research is closed when the loop adds no new entities, or the
cap is hit and the residual is listed under Risks as "unexplored".

## Phase P — Planning (present to the user)

7. Draft: affected entities, proposed changes per entity, blast radius
   (`graph_query(incoming)` + `trace_path`), coverage plan, task sketch.
8. **USER GATE 1** — present the research summary + plan outline. Ask if the
   user is satisfied. Iterate. **Do NOT create any file before approval.**

## Phase S — Specification (only after approval)

9. Create `batho-specs/NN-<name>/` — NN = next two-digit number (list
   `batho-specs/`, take max + 1, zero-pad to 2). `<name>` = kebab-case name.
10. Write `specs_<name>.md` from `references/spec-template.md`.
11. **USER GATE 2** — ask: "proceed with execution?" Yes → invoke
    **batho-execute** with the spec path. No → stop.

## Grounding rules (non-negotiable)

- Every Current-Behavior row cites `entity_id` + `file:line` (+ relationships).
  A spec with zero citations is invalid — do not write it.
- Cite, don't paste: never inline file contents; reference `entity_id` + location.
- Name the tool that produced each fact implicitly via the citation format.

## Folder & file conventions

- `batho-specs/NN-<name>/` at the repo root; NN zero-padded, increments per spec
  (scan existing folders, max + 1).
- `specs_<name>.md` — this skill's output (the grounded truth).
- `plan_<name>.md` (batho-execute) and `review_<name>.md` (batho-review) join it later.
- `<name>` is kebab-case and identical in folder and file names.

## Token budgets

- `graph_overview`: `summary` (12k tokens) unless deep dive.
- `search_entities`: `limit=25`; `graph_query`: `limit=50` per hop.
- `get_entity(include_source=true)` only for entities entering the spec.
- Research loop caps: 3 rounds, 40 entities — state when a cap truncates.

## References (load on demand)

- `references/spec-template.md` — the canonical spec template (the contract
  shared with batho-execute and batho-review)
- `references/workflows.md` — research-loop pseudocode, gate scripts, examples
- `references/fallbacks.md` — zero-result, no-graph, and greenfield paths

## Hard rules

1. Research → plan → **user approval** → write file. Never write first.
2. Every Current-Behavior row cites `entity_id` + `file:line`. Zero citations = invalid spec.
3. After writing, always offer execution (batho-execute). Never auto-execute.
4. Multi-repo: pass `repo` explicitly.
5. Spec file is append-friendly but versioned by folder — never edit a spec
   after execution starts without noting the change in Provenance.
