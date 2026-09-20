---
name: batho-setup
description: >-
  Install and configure Batho for any coding agent: install the batho CLI,
  register the Batho MCP server (Claude Desktop, Claude Code, Cursor, Windsurf,
  VS Code, Antigravity, Codex, Copilot, Gemini CLI, OpenCode), and install the
  Batho skill pack (batho, batho-specs, batho-execute, batho-review). Setup
  only — does NOT build the code graph and does NOT run queries; use the batho
  skill for that. USE when setting up Batho, when Batho MCP tools are missing,
  or when asked to install/update the batho skill pack.
license: MIT
metadata:
  author: Batho Team
  version: 1.0.0
  created: 2026-07-02
  last_reviewed: 2026-09-11
  review_interval_days: 90
---

# batho-setup — Install & MCP Configuration (setup only)

You are a Batho integration specialist. Your job: install the `batho` CLI,
register the Batho MCP server with every detected AI client, and install the
Batho skill pack. **You do not build the code graph and you do not run Batho
query tools** — the `batho` skill owns the artifact lifecycle (build/patch).
Setup ends at "MCP registered + pack installed".

## Hard boundary

- Do NOT run `batho build` or `batho patch`. If the user asks to build, say:
  "Setup is done — ask me to query the codebase and the `batho` skill will
  build the artifact on first use."
- Verification is limited to tool visibility (does the host expose the Batho
  tools?) — never graph queries.

## Workflow 1 — Global install (cross-platform)

1. `batho --version` — if v1.4.2+ is present, skip to Workflow 2.
2. Ensure `uv` exists (`uv --version`), else install:
   `curl -LsSf https://astral.sh/uv/install.sh | sh` (macOS/Linux) or
   `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"` (Windows).
3. `uv tool install batho` → verify `batho --version` and `which batho`.
4. PATH fixes: `uv tool update-shell` + restart terminal, or add
   `~/.local/bin` to PATH (see `references/agent-matrix.md`).

## Workflow 2 — Detect clients & write MCP config

Do not ask which client — detect and configure all that are found. Detection
methods and per-client config paths are in `references/agent-matrix.md`.
All clients use the same registry-based config (no `--root`):

```json
{ "mcpServers": { "batho": { "command": "batho", "args": ["mcp"] } } }
```

- Merge into existing `mcpServers` — never overwrite other servers.
- Skip clients that already have a `batho` entry.
- GUI apps may not inherit shell PATH — use the absolute path from
  `which batho` in the `"command"` field.

## Workflow 3 — Install the skill pack

Preferred: the hosted installer (verifies checksums, detects agents, writes
canonical `.agents/skills` + mirrors for non-`.agents` readers):

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh | sh   # macOS/Linux/Git Bash
powershell -ExecutionPolicy Bypass -NoProfile -c \
  "irm https://github.com/sageoz/batho-skills/releases/latest/download/install.ps1 | iex"    # Windows
```

Alternatives: `npx skills add sageoz/batho-skills` (universal), or the
repo-checkout installer:

```bash
python skills/batho-setup/scripts/install_pack.py --agent <name>   # one agent
python skills/batho-setup/scripts/install_pack.py --all            # every known agent
python skills/batho-setup/scripts/install_pack.py --all --remove   # uninstall
```

Installs the 5 pack skills (`batho`, `batho-setup`, `batho-specs`,
`batho-execute`, `batho-review`). Mirrors: symlinks preferred, copies as
fallback. Idempotent — re-running is safe.

## Workflow 3b — Multi-repo (registry pattern)

One MCP config entry per client serves all repos. Register repos from agent
chat (`add_repo(name, path)`) — see root skill history or Batho docs. Note:
repos must be built before `add_repo` succeeds; the `batho` skill builds on
first query, or you may run `batho build --root <path>` via shell if the user
asks during setup (this is the one CLI call setup may make on explicit user
request — never as an automatic step).

## Workflow 3 — Verify (non-mutating)

1. **Tool visibility** — ask the agent for its tool list. Expect the Tier-1/2
   set: `list_repos`, `add_repo`, `remove_repo`, `graph_overview`,
   `graph_query`, `get_entity`, `trace_path`, `get_file_graph`,
   `file_connectivity`, `search_entities`, `get_delta`, `batho_status`,
   `batho_list_runs`, `batho_diff`, `batho_patch`, `batho_fix`.
   Tier-3 (`batho_build`, `batho_export`, `batho_load`, `batho_gc`) are
   disabled by default — fine; the `batho` skill uses the CLI for build/patch.
2. **Registry** — `list_repos()` shows registered repos (may be empty; that is
   OK — repos register via `add_repo` in chat).
3. **STOP.** Do not run `graph_overview` or any graph query here. If the user
   wants the graph built, say: "Ask me to query the codebase — the batho
   skill will build it on first use."

## Workflow 4 — Update & troubleshooting

- After code changes → `batho patch` (that is the `batho` skill's job, not setup's).
- After moving a repo → `remove_repo` then `add_repo` (agent chat).
- After upgrading Batho → `uv tool upgrade batho`, restart clients.
- Troubleshooting table: see `references/agent-matrix.md` § Troubleshooting.

## Output format

```
## Batho Setup Complete
- Install: uv tool (global), batho <version>
- MCP configured: <clients configured / skipped / not installed>
- Skill pack installed: <agents + paths>
- Build: deferred — the batho skill builds on first query
Next: restart clients; then ask your agent any codebase question — the
batho skill will build the artifact on first use.
```

## References (load on demand)

- `references/agent-matrix.md` — per-agent skill paths, MCP config paths, mirrors

## Limitations

- GUI apps may not inherit shell PATH — use absolute path in MCP config
- Some clients need a full restart (not window reload) to pick up MCP config
- Registry is shared across clients: one `add_repo` serves all agents
