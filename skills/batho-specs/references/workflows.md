# batho-specs — Workflows, Gates, and Examples

## Research loop (Phase R, step 4 in SKILL.md)

```
frontier = anchors(search_entities per domain noun)
visited  = {}
for round in 1..3:                      # cap: 3 rounds
    frontier_next = []
    for ent in frontier:
        if ent in visited: continue
        visited[ent] = get_entity(ent)          # all incoming + outgoing rels
        for rel in visited[ent].edges:
            if rel.type in {CALLS, USES, IMPORTS, INHERITS, IMPLEMENTS, OVERRIDES}:
                frontier_next.append(rel.target)
    frontier = [e for e in frontier_next if e not in visited]
    if not frontier: break                  # closure reached
if len(visited) >= 40: log "entity cap hit; residual unexplored"
```

Closure = a full pass adds no new entities. Record `rounds_used`, `entities_visited`,
and any cap truncation in the spec's Provenance/Risks.

## Gate scripts (what to say to the user)

**Gate G1 (research closure):**
> Research closed after N rounds: M entities visited, K relationships mapped.
> Unexplored (cap): <list or "none">.

**Gate G2 (approval — before ANY file creation):**
> Here is the research summary and plan outline: <…>
> Satisfied with this research and approach? I will write the spec to
> `batho-specs/NN-<name>/specs_<name>.md` only after your approval.

Iterate on feedback. Only after an explicit yes:

**Gate G3 (execution offer, after writing the spec):**
> Spec written to `batho-specs/NN-<name>/specs_<name>.md`.
> Proceed with execution? (yes → batho-execute / no → stop here)

## Folder numbering

```python
# pseudo: next NN
existing = [d for d in listdir("batho-specs") if d[:2].isdigit()]
next_nn = f"{max(int(d[:2]) for d in existing) + 1:02d}" if existing else "01"
```

## Worked example (abridged)

Request: "add a --json flag to batho status output"

1. `batho_status` → artifact gen 948, fresh.
2. `search_entities(query="status", entity_types=["FUNCTION"])` → `batho_status` (tools.py:1987).
3. `get_entity(batho_status)` → outgoing CALLS → `format_status_markdown`, `build_status_structured`; incoming ← `register_tools`.
4. Round 2: `get_entity(format_status_markdown)` → no new entities → closure (2 rounds, 6 entities).
5. Reuse check: `search_entities(query="format")` → `format_delta_markdown` exists — note as pattern reference, not duplicate.
6. Boundary: `file_connectivity("batho/mcp/tools.py", direction="incoming")` → 0 repo dependents → MINOR.
7. Present plan → user approves → write `batho-specs/01-json-status-flag/specs_json-status-flag.md`
   with §2 rows citing `batho_status` (tools.py:1987) etc.

## Common mistakes

| Mistake | Correction |
|---|---|
| Writing the spec before approval | Gate G2 is absolute — present, wait, then write |
| Pasting file contents into §2 | Cite `entity_id` + `file:line`; the graph is the source |
| Ending research after one search | Run the closure loop; one pass is not closure |
| Spec without Provenance generation | Record `artifact_generation` — review depends on it |
| Creating `plan_<name>.md` here | That is batho-execute's output; stop after specs file + execution offer |
