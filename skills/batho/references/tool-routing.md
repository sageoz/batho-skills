# Tool Routing — every query/diagnostic tool with shapes and examples

All tools accept optional `repo` (default: first registered repo). All return
dual output: markdown `content` + `structuredContent` JSON. Errors carry a
`hint` field — follow it.

The 12 query/diagnostic tools: `list_repos`, `graph_overview`, `graph_query`,
`get_entity`, `trace_path`, `get_file_graph`, `file_connectivity`,
`search_entities`, `get_delta`, `batho_status`, `batho_list_runs`,
`batho_diff` — plus the registry pair `add_repo` / `remove_repo` (14 total).

---

## list_repos — what repos exist?

- **Input**: none.
- **Output**: `repos[]` (name, path, has_artifact, entity_count, watch, sync_state), `total`.
- **Example**: session start → `list_repos()` → pick repo name for all later calls.

## graph_overview — architecture first pass

- **Input**: `response_format` (`summary`|`concise`|`detailed`), `max_tokens`.
- **Output**: `overview.stats` (entity/relationship/file counts, breakdowns), `overview.communities[]`, `meta`.
- **Example**: "what does this codebase do?" → `graph_overview(response_format="summary")` → then drill into communities with `graph_query`.

## search_entities — find a symbol by name

- **Input**: `query` (substring/regex, ≤200 chars), `entity_types`, `entity_categories`, `symbol_roles`, `limit` (default 25), `response_format`.
- **Output**: `results[]` (entity_id in backticks, type, file:line), `meta.total_matches`.
- **Example**: "where is `register_tools`?" → `search_entities(query="register_tools", entity_types=["FUNCTION"])` → feed the entity_id to `get_entity`.

## get_entity — deep-dive one symbol

- **Input**: `entity_id` (id or display name), `include_source` (default false), `response_format`.
- **Output**: `graph.nodes` (1) + `graph.edges` (incoming+incoming rels), `meta`.
- **Example**: "who calls `register_tools`?" → `get_entity(entity_id="…", response_format="concise")` → read incoming `CALLS` edges.

## graph_query — filtered graph traversal

- **Input**: `file_path`, `entity_types`, `entity_categories`, `relation_types`, `symbol_roles`, `confidence_threshold`, `relation_direction` (`outgoing`|`incoming`|`both`), `name_pattern`, `limit` (default 50), `offset`, `response_format`, `max_tokens`.
- **Output**: `graph.nodes[]` + `graph.edges[]`, `meta` (totals, applied_filters, pagination).
- **Example**: "what depends on `batho/mcp/tools.py`?" → `graph_query(file_path="batho/mcp/tools.py", relation_direction="incoming", relation_types=["IMPORTS","CALLS"])`.

## trace_path — how does A reach B?

- **Input**: `source_entity_id`, `target_entity_id`, `max_depth` (default 5, max 20), `relation_types`, `relation_direction` (default `outgoing`), `confidence_threshold`, `response_format`.
- **Output**: `path[]` (entity_id, relation_type, name per hop), `depth`, `meta`.
- **Example**: "how does the CLI reach the storage layer?" → resolve both ends with `search_entities`, then `trace_path(source, target, max_depth=10)`.

## get_file_graph — what's in a file?

- **Input**: `file_path` (forward slashes), `include_cross_file_refs` (default true), `response_format`, `max_tokens`.
- **Output**: `graph.nodes[]` + `graph.edges[]` scoped to the file, `meta`.
- **Example**: "what's in `server.py`?" → `get_file_graph(file_path="batho/mcp/server.py")` instead of reading the file.

## file_connectivity — file-level dependencies

- **Input**: `file_path`, `direction` (`outgoing`|`incoming`|`both`), `include_external`, `min_confidence`, `response_format`.
- **Output**: `depends_on[]` / `depended_on_by[]` cells (file, relations{TYPE: count, max_confidence, via[]}), `external`, `stats`, `meta`.
- **Example**: "who breaks if I change `registry.py`?" → `file_connectivity(file_path="batho/mcp/registry.py", direction="incoming")`.

## get_delta — what changed in the last patch?

- **Input**: `run_id` (default: latest patch run), `change_kind` (`added`|`removed`|`modified`|`renamed`), `file_path`, `limit` (default 100), `offset`, `response_format`.
- **Output**: `changes[]`, `delta_stats` (nodes_added/removed/modified/renamed, churn_pct), `run_info`.
- **Example**: post-edit verification → CLI `batho patch` → `get_delta(file_path="batho/mcp/tools.py")` → confirm added/modified match intent.

## batho_status — freshness gate

- **Input**: `repo` (None = all repos).
- **Output**: `repos[]` (has_artifact, run_count, latest_run_uuid, watching, sync_state, pending_sync_files, last_synced), `total`.
- **Example**: session start → `batho_status()` → stale? patch. Missing? build.

## batho_list_runs — run history

- **Input**: `repo`, `limit` (default 20).
- **Output**: `runs[]` (run_uuid, run_type, created_at, git_commit), `total_runs`.
- **Example**: pick a run_id for `batho_diff` or `get_delta(run_id=…)`.

## batho_diff — structural history

- **Input**: exactly ONE of `run_id` / `entity_id` / `file_path`; optional `since` (with entity_id).
- **Output**: change records (entity names, change kinds) for the target.
- **Example**: "how has `register_tools` evolved?" → `batho_diff(entity_id="…")`.

## add_repo / remove_repo — registry management

- **add_repo input**: `name`, `path` (absolute), `watch`, `debounce_ms`, `max_file_size_kb`. Output: registered entry + entity_count.
- **remove_repo input**: `name`. Output: removed name. Does NOT delete the artifact on disk.
- **Example**: "add this repo" → `add_repo(name="myapp", path="/abs/path", watch=true)` (repo must already have a `.batho` artifact).

---

## Chaining patterns

- **Onboard**: `list_repos` → `graph_overview` → `search_entities(domain noun)` → `get_entity`.
- **Impact**: `search_entities(X)` → `get_entity` (incoming) → `trace_path` for depth → `file_connectivity` for file-level blast.
- **Review a change**: `batho patch` (CLI) → `get_delta` → `get_entity` per changed node.
- **Spec grounding**: `graph_query(file_path=…)` → `get_entity` per anchor → `trace_path` between anchors.
