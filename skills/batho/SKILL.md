---
name: batho
description: >
  Answer codebase questions and route code work through the Batho code graph (MCP). USE for
  ANY question about the codebase: where code lives, who calls/uses a symbol, dependencies,
  call paths, architecture, impact of changes, pre-work research. Also USE FIRST in any session
  to ensure the Batho artifact exists and is fresh for this workspace (batho build / batho
  patch / batho_status). Routes feature work to batho-specs, implementation to batho-execute,
  verification to batho-review. DO NOT USE for exact-string search, editing files, git history,
  or running tests — use Grep/Edit/Glob/Bash for those. Read files only after the graph has
  named the files worth reading.
metadata:
  version: 1.0.0
---

# batho — Universal Router + Artifact Lifecycle

You are the Batho entry point. Two jobs: (1) keep the `.batho` artifact for this
workspace present and fresh, (2) route every codebase question through Batho MCP
tools before any file reading, and route work to the lifecycle skills
(`batho-specs`, `batho-execute`, `batho-review`). You are the only skill that
builds/patches; every other skill in the pack assumes you ran.

## 1. Artifact lifecycle (runs first, every session)

1. Call `batho_status` (multi-repo: `list_repos` first, then per-repo status).
2. **No artifact** → build it. Default: CLI `batho build --root <path>` via shell.
   If the MCP tool list includes `batho_build` (Tier-3 enabled), you may call it
   instead. Re-check `batho_status`. Report entity/relationship counts when done.
3. **Stale artifact** (staleness banner on any tool result, or `batho_status`
   generation behind the working tree) → CLI `batho patch --root <path>` (or the
   `batho_patch` MCP tool if enabled) → confirm the new `artifact_generation`.
4. Record `artifact_generation` in your working notes. Every later Batho skill
   re-checks it; treat a mismatch as stale and patch again.
5. `batho build --force` only when the user asks for a rebuild; plain
   `batho build` is incremental-safe.

## 2. Query routing (graph names files; files are read last)

| Question type | Batho tool | Key params | Replaces |
|---|---|---|---|
| Where is symbol X / what is it | `search_entities(query=X)` → `get_entity(entity_id)` | `response_format=concise` until chosen | `grep -rn "def X"` + opening files |
| Who calls / uses X | `get_entity` (incoming rels) or `graph_query(name_pattern=X, relation_direction=incoming)` | `relation_types=[CALLS,USES]` | grep + manual call-site triage |
| What does X depend on | `get_entity` (outgoing) or `file_connectivity(file_path)` | `direction=both` for review | import crawling |
| How does A reach B | `trace_path(source, target)` | `max_depth≤10`, `relation_direction=outgoing` | multi-hop grep chains |
| What's in file F / what does it touch | `get_file_graph(file_path)` | `include_cross_file_refs=true` | reading the whole file |
| Architecture overview | `graph_overview(response_format=summary)`; `architecture_overview` prompt optional | — | ad-hoc file skimming |
| What changed structurally | `get_delta` / `batho_diff` / `batho_list_runs` | `change_kind` filter | git-diff spelunking for structure |
| Impact of changing X | route to `batho-specs` (planned) or inline `trace_path` + `file_connectivity` | — | grep for name + hope |

**File-read cap:** if you have read >3 files just to *understand* (not edit),
stop and re-query the graph — the graph names the files worth reading.

## 3. Routing to lifecycle skills

| User intent | Route to |
|---|---|
| "implement / add / build a feature", "write a spec", "plan this change" | **batho-specs** |
| "execute / implement spec NN-x" (or after batho-specs completion) | **batho-execute** |
| "review / verify spec NN-x" | **batho-review** |
| One-off question (no artifact change) | answer directly via §2 |
| "install / set up Batho", "Batho MCP tools missing" | **batho-setup** |

When routing, state which skill and why, then continue in that skill's workflow.
Spec/work artifacts live in `batho-specs/NN-<name>/` at the repo root — never
inside Batho's install.

## 4. Fallbacks (state the reason)

- Zero graph results → say so, then fall back to grep/glob (see
  `references/fallbacks.md`). Recommend `batho build` if the artifact is missing.
- Tool error → follow the `hint` in structuredContent; `list_repos` for repo
  issues, `search_entities` for entity_id issues.
- Exact strings (log messages, literals, TODOs) are grep's job — say so and use
  grep directly.

## 5. Token budgets (defaults)

- `response_format`: `summary` for orientation, `concise` for queries,
  `detailed` only for deep dives.
- `max_tokens` 25000 default; lower it (e.g. 8000) for broad `graph_query` scans.
- Paginate with `offset`/`limit` instead of re-running broad queries.
- `get_entity(include_source=true)` only for symbols in the current edit set.

## References (load on demand)

- `references/artifact-lifecycle.md` — build/patch decision tree, freshness semantics
- `references/tool-routing.md` — every query/diagnostic tool with shapes + examples
- `references/anti-patterns.md` — grep-era habits and their Batho replacements
- `references/fallbacks.md` — legitimate grep/read/glob cases

## Hard rules

1. Freshness gate first: `batho_status` before any graph read. Stale → patch → re-check.
2. Build/patch default to CLI (`batho build`, `batho patch`); MCP Tier-3 tools
   only when present in the tool list. Never call tools not in your tool list.
3. Multi-repo: resolve via `list_repos`; never assume `default`.
4. After build/patch, surface the new `artifact_generation`.
5. Never paste file contents into answers when a graph citation
   (`entity_id` + `file:line`) suffices.
