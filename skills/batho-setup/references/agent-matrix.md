# Agent Matrix — skill paths, MCP config paths, mirrors

Canonical source: `skills/` in the `sageoz/batho-skills` repo. The machine-readable
form used by `install.sh` / `install.ps1` / `install_pack.py` is
`agent-paths.json` at repo root — keep this table and that file in sync.
Upstream reference for new agents: `github.com/vercel-labs/skills` `src/agents.ts`.

## Install strategy

Write canonical copies into `.agents/skills/` (project) or `~/.agents/skills/`
(global), then mirror (symlink preferred, copy fallback) only into agents that
do NOT read `.agents/skills` natively. Claude Code is the mandatory mirror —
it never reads `.agents/skills`.

## Skill discovery paths (where each agent reads SKILL.md)

| Agent | Project skills (read) | Global skills | Needs mirror? |
|-------|----------------------|---------------|---------------|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` | **yes** (never reads `.agents`) |
| Cursor (2.4+) | `.agents/skills/`, `.cursor/skills/`; compat `.claude/skills/`, `.codex/skills/` | `~/.agents/skills/`, `~/.cursor/skills/`; compat `~/.claude/skills/`, `~/.codex/skills/` | no |
| GitHub Copilot (VS Code, VS, CLI, cloud) | `.github/skills/`, `.claude/skills/`, `.agents/skills/` | `~/.copilot/skills/`, `~/.agents/skills/`, `~/.claude/skills/` (legacy) | no |
| OpenAI Codex | `.agents/skills/` (CWD + ancestors to repo root); `.codex/skills/` via project config | `~/.agents/skills/` (canonical); `~/.codex/skills/` deprecated but scanned; `/etc/codex/skills/` admin | no |
| Gemini CLI | `.gemini/skills/` or `.agents/skills/` (alias) | `~/.gemini/skills/` or `~/.agents/skills/` (alias) | no (alias) |
| OpenCode | `.opencode/skills/`, `.claude/skills/`, `.agents/skills/` (walks to worktree) | `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | no |
| Windsurf / Cascade (Devin Desktop) | `.windsurf/skills/`; compat `.agents/skills/`; `.claude/skills/` if CC-config reading enabled | `~/.codeium/windsurf/skills/`; compat `~/.agents/skills/`; `~/.claude/skills/` if enabled | optional (`.agents` read is native now) |
| Devin (product) | `.agents/skills/`, `.claude/skills/`, `.cursor/skills/`, `.codex/skills/`, `.cognition/skills/`, `.github/skills/`, `.windsurf/skills/` | backend-indexed | no (scans all seven) |
| Devin CLI | `.devin/skills/`, `.agents/skills/`, `.windsurf/skills/` | `~/.config/devin/skills/`, `~/.agents/skills/`, `~/.codeium/<channel>/skills/`; Windows `%APPDATA%\devin\skills\` | no |
| Amp | `.agents/skills/` (project + parents); `.claude/skills/` | `~/.config/agents/skills/` (install target), `~/.agents/skills/`, `~/.config/amp/skills/`, `~/.claude/skills/` | no |
| Roo Code | `.roo/skills/`, `.roo/skills-<mode>/`, `.agents/skills/` (+ mode variants) | `~/.roo/skills/`, `~/.agents/skills/` (+ mode variants) | optional (native `.roo` dir) |
| Cline | `.cline/skills/`; `.agents/skills/` (installer-mapped, verify per release) | `~/.cline/skills/` (Win `%USERPROFILE%\.cline\skills`) | yes (`.cline/skills/`) |
| Zed | `.agents/skills/` only | `~/.agents/skills/` only | no (only dir it reads) |
| Kiro | `.kiro/skills/` (custom agents need `skill://` resource glob) | `~/.kiro/skills/` | yes (`.kiro/skills/`) |
| Factory Droid | `.factory/skills/`; compat `.agent/skills/` (singular) | `~/.factory/skills/` | yes (`.factory/skills/`) |
| Trae IDE | `.trae/skills/`; `.agents/skills/` community-reported | `~/.trae/skills/`; Win `%userprofile%\.trae\skills` | yes (`.trae/skills/`) |
| Google Antigravity | `.agents/skills/` (+ `.agent/skills` legacy); CLI `agy` same | `~/.gemini/antigravity/skills/` (IDE docs) **and** `~/.gemini/config/skills/` (docs/skills page — official pages conflict, write both); `agy` CLI `~/.gemini/antigravity-cli/skills/` | no (`.agents` native) + global mirrors |
| JetBrains Junie | `.junie/skills/` (IDE); `.agents/skills/` (Junie CLI, trusted project) | `~/.junie/skills/`; CLI also `~/.agents/skills/` | yes (`.junie/skills/` for IDE) |
| Goose (Block) | `.agents/skills/` canonical; compat `.goose/skills/`, `.claude/skills/` | `~/.agents/skills/` canonical; compat `~/.claude/skills/`, `~/.config/agents/skills/` | no |
| Warp | `.agents/skills/` recommended + 9 others (`.warp`, `.claude`, `.codex`, `.cursor`, `.gemini`, `.copilot`, `.factory`, `.github`, `.opencode`) | same 10 dirs under `~/` | no (widest scanner) |
| Pi | `.pi/skills/`, `.agents/skills/` (cwd + ancestors) | `~/.pi/agent/skills/`, `~/.agents/skills/` | no |
| Continue | `.continue/skills/`, `.claude/skills/` | `~/.continue/skills/`, `~/.claude/skills/` | yes (`.continue/skills/`) |
| Kilo Code | `.kilocode/skills/`; `.agents/skills` likely (Roo fork) | `~/.kilocode/skills/` | yes (`.kilocode/skills/`) |
| Aider | — none — load SKILL.md via `--read` | — | n/a (no support) |
| Amazon Q Developer CLI | — none (JSON agents only; Kiro is the successor) | — | n/a (no support) |

**Key facts:**
- `.agents/skills/` is the vendor-neutral convention (recommended by the
  agentskills.io client-implementation guide) but is NOT read natively by
  Claude Code or Kiro's default agent — hence mirrors.
- Codex canonical user dir is `~/.agents/skills/` — `~/.codex/skills/` is
  deprecated but still scanned; `/etc/codex/skills/` is the admin/enterprise
  push target.
- Precedence is project > global on name clash everywhere (Cline reportedly
  prefers global — edge case).
- Windows global paths differ: `%USERPROFILE%\.cline\skills`,
  `%userprofile%\.trae\skills`, `%APPDATA%\devin\skills`.

## MCP config paths

| Client | Config path | Config body |
|--------|-------------|-------------|
| Claude Desktop | `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) / `%APPDATA%\Claude\...` (Win) / `~/.config/Claude/...` (Linux) | `{"mcpServers":{"batho":{"command":"batho","args":["mcp"]}}}` |
| Claude Code | `.mcp.json` (project) or `claude mcp add` | same |
| Cursor | `.cursor/mcp.json` (project) | same |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` | same |
| VS Code | per MCP extension docs; command `batho mcp` | — |
| Antigravity | `~/.gemini/antigravity/mcp_config.json` (or `~/.gemini/config/mcp_config.json`) | same |

Merge `batho` into existing `mcpServers` — never overwrite other servers.
Use the absolute `batho` path for GUI clients that don't inherit shell PATH.

## Mirror strategy

- Prefer **symlinks** (`ln -s <repo>/skills/<name> <target>/<name>`) — single
  source of truth.
- Fall back to **copy** on filesystems without symlink support (some Windows
  configs); installers accept `--copy` / `BATHO_COPY=1` to force copies.
- Never hand-edit mirrored copies.

## Tier-3 enablement (for reference only — setup does not enable)

`batho_build`, `batho_patch`, `batho_export`, `batho_gc` are disabled by
default. Enable via `batho.yaml` (`mcp.tools.disabled: []`), env
(`BATHO_MCP_TOOLS_DISABLED=""`), or `batho mcp --enable-tool <name>`. Without
them, the `batho` skill uses the CLI (`batho build` / `batho patch`) — setup
does not need to enable anything.

## Troubleshooting (setup-scoped)

| Issue | Fix |
|-------|-----|
| `batho` not on PATH | `uv tool update-shell` + restart terminal; or add `~/.local/bin` to PATH |
| GUI client can't find `batho` | absolute path in config `"command"` field |
| Tools not appearing | validate config JSON; check client restarted |
| `batho mcp` hangs | expected — stdio server waits for input |
| "No Batho artifact found" at query time | NOT a setup problem — the `batho` skill builds it; or run `batho build --root <path>` manually |
| Antigravity skills not found | write both `~/.gemini/antigravity/skills/` and `~/.gemini/config/skills/` — official docs conflict |
