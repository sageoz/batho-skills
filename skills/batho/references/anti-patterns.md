# Anti-patterns — grep-era habits and their Batho replacements

Each habit below wastes tokens and produces worse answers than the graph.
Catch yourself doing these; route to the tool instead.

1. **`grep -rn "def foo"` to locate a symbol**
   → `search_entities(query="foo", entity_types=["FUNCTION"])`. Structured
   results with entity_ids, no file opening.

2. **Opening a file to "see what's in it"**
   → `get_file_graph(file_path=…)`. Entities + relationships in one call;
   read the file only when you intend to edit it.

3. **Grepping for a name to find callers, then reading each hit**
   → `get_entity(entity_id=…)` incoming `CALLS` edges, or
   `graph_query(name_pattern=…, relation_direction="incoming")`. The graph
   already resolved the call sites — including the ones grep can't see
   (dynamic dispatch, re-exports).

4. **Chaining greps to trace a call path (A calls B calls C …)**
   → `trace_path(source, target, max_depth≤10)`. BFS over the pre-built
   graph with relation types per hop.

5. **Reading imports at the top of files to map dependencies**
   → `file_connectivity(file_path=…, direction="both")`. Resolved,
   aggregated, confidence-scored file-level edges with `via` symbols.

6. **`git diff` to understand what a change did structurally**
   → `get_delta(run_id=…)` / `batho_diff(…)`. Node-level
   added/removed/modified/renamed with stats — git diff shows lines, the
   graph shows structure.

7. **Skimming the repo tree to "get a feel" for the architecture**
   → `graph_overview(response_format="summary")` then community drill-down
   via `graph_query`. Counts, breakdowns, communities — then targeted reads.

8. **Reading >3 files to understand before any edit**
   → Stop. Re-query the graph. Files are read last (for editing), not first
   (for understanding). The graph names the files worth reading.

9. **Re-running a broad grep after every edit to "stay current"**
   → `batho patch` (CLI) once, then `get_delta`. The artifact updates
   incrementally; your mental model should too.

10. **Assuming the artifact is fresh because it exists**
    → `batho_status` first, every session. Stale graphs silently produce
    wrong answers; the freshness gate is cheap.

11. **Pasting whole file contents into specs/plans/reviews**
    → Cite `entity_id` + `file:line`. Grounded artifacts reference the
    graph; they don't duplicate it.
