# Artifact Lifecycle — build / patch / freshness decision tree

The `batho` skill owns this. Other pack skills assume it ran.

## Decision tree

```
batho_status(repo?)
├─ artifact missing?
│   ├─ YES → BUILD:
│   │   1. Prefer CLI: batho build --root <path>
│   │   2. If batho_build is in the MCP tool list (Tier-3 enabled):
│   │      call batho_build(repo) directly.
│   │   3. Re-run batho_status → expect ✓ present, N runs.
│   │   4. Report entity/relationship counts to the user.
│   └─ NO → staleness?
│       ├─ staleness banner on any tool result, OR
│       │  batho_status sync_state != idle / pending_files non-empty, OR
│       │  artifact_generation unchanged despite known edits
│       ├─ YES → PATCH:
│       │   1. Prefer CLI: batho patch --root <path>
│       │   2. If batho_patch is in the tool list: call it directly.
│       │   3. Re-run batho_status → new latest run_uuid.
│       │   4. get_delta(repo) for reconciliation (what changed).
│       └─ NO → proceed to queries.
```

## CLI-first, MCP second

Tier-3 tools (`batho_build`, `batho_patch`, `batho_export`, `batho_gc`) are
disabled by default — they will NOT appear in the tool list. Probe the tool
list once:

- Present → you may call the MCP tool (it locks internally, safe to run
  mid-session).
- Absent → run the CLI via shell: `batho build --root <path>` /
  `batho patch --root <path>`. Never tell the user a build is impossible;
  the CLI always works.

`batho build --force` (full rebuild) only when the user explicitly asks or
the artifact is corrupt (see `batho_fix`). Plain `batho build` is
incremental-safe and cheap on an up-to-date repo.

## Freshness semantics

- `artifact_generation` is a monotonic integer in every tool's `meta`.
  Record it at session start; any later mismatch means someone patched —
  re-anchor entity IDs before continuing spec work.
- `batho_status` fields that signal staleness: `sync_state`
  (`pending`/`patching`/`error`), non-empty `pending_sync_files`, a
  staleness banner injected into tool results by the watcher.
- `get_delta(repo, run_id=<latest>)` reconciles after a patch: expect
  `nodes_added` / `nodes_removed` / `nodes_modified` matching the edits
  you made. Unexpected removals → stop and explain before continuing.
- Watcher-enabled repos (`watch: true` in `list_repos`) auto-patch after a
  debounce; manual `batho patch` is still correct when you need the graph
  current *now*.

## Multi-repo

- Never assume `default`. `list_repos` first; pass `repo=<name>` to every
  subsequent call.
- Each repo has its own artifact generation and run history — track them
  separately.

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| "No runs found" | artifact never built | CLI `batho build --root <path>` |
| "No patch runs found" | no incremental changes yet | CLI `batho patch --root <path>` |
| Tool missing from list | Tier-3 disabled (default) | use CLI; or document enablement (`batho.yaml` `mcp.tools.disabled: []`, `mcp.toolsets: {admin: true}`, or `batho mcp --enable-tool <name>`) |
| Artifact fails to load | corruption | `batho_fix` if enabled, else CLI `batho fix --root <path>`; last resort `batho build --force` |
