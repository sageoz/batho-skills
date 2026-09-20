# Batho Skills

[![validate](https://github.com/sageoz/batho-skills/actions/workflows/validate.yml/badge.svg)](https://github.com/sageoz/batho-skills/actions/workflows/validate.yml)
[![release](https://img.shields.io/github/v/release/sageoz/batho-skills)](https://github.com/sageoz/batho-skills/releases)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

# Skill pack for [Batho](https://github.com/sageoz/Batho)

## Quick Install

**Universal — one command, every agent** (Claude Code, Cursor, Codex, Copilot,
Gemini CLI, OpenCode, Amp, Zed, Windsurf, Devin, Goose, Warp… 70+):

```bash
npx skills add sageoz/batho-skills
```

The CLI detects which agents you have installed and writes each skill where
that agent looks.

<details>
<summary><strong>Other install methods</strong></summary>

### Claude Code (plugin marketplace)

```bash
/plugin marketplace add sageoz/batho-skills
/plugin install batho@batho
```

### OpenAI Codex

```bash
codex plugin marketplace add sageoz/batho-skills
```

### Gemini CLI

```bash
gemini extensions install sageoz/batho-skills
```

### GitHub Copilot

```bash
gh skills install sageoz/batho-skills
```

### curl installer (macOS / Linux / Git Bash / WSL)

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh | sh
```

### PowerShell (Windows)

```powershell
powershell -ExecutionPolicy Bypass -NoProfile -c "irm https://github.com/sageoz/batho-skills/releases/latest/download/install.ps1 | iex"
```

### Manual

Copy `skills/<name>` into `<scope>/.agents/skills/` — every agent listed in
[agent-paths.json](agent-paths.json) reads from there or gets a mirror.

</details>

### Pin a version

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/download/v1.0.0/install.sh | sh   # pinned URL
# or
BATHO_VERSION=1.0.0 sh -c "$(curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh)"
```

## What You Get

| Skill | Purpose |
|---|---|
| `batho` | Router + artifact lifecycle — build/refresh the code graph, answer structural questions via MCP |
| `batho-setup` | Install the `batho` CLI, register the MCP server in your agent, install this pack |
| `batho-specs` | Graph-grounded specifications — every claim cites entities from the code graph |
| `batho-execute` | Spec-driven implementation — dependency-ordered tasks with pre-edit grounding |
| `batho-review` | Graph-verified review — per-criterion PASS/FAIL with structural delta reports |

Plus a bundled `batho` MCP server registration (`mcp.json`, `.mcp.json`,
`gemini-extension.json`) and an opt-in nudge hook (`hooks/`, disabled by
default).

## Requirements

The skills drive the [Batho CLI](https://github.com/sageoz/Batho). Install it
once — `batho-setup` can do this for you:

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install-batho.sh | sh   # macOS / Linux
# Windows:
powershell -ExecutionPolicy Bypass -NoProfile -c "irm https://github.com/sageoz/batho-skills/releases/latest/download/install-batho.ps1 | iex"
# or directly: uv tool install batho (or pipx install batho)
```

## Verify Before Running

All release artifacts are deterministic, checksummed, and SLSA-attested:

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh | less   # inspect
# or download-verify-run:
curl -fsSLO https://github.com/sageoz/batho-skills/releases/latest/download/install.sh
curl -fsSLO https://github.com/sageoz/batho-skills/releases/latest/download/sha256sums.txt
sha256sum --check sha256sums.txt --ignore-missing
gh attestation verify install.sh --repo sageoz/batho-skills       # SLSA provenance
sh install.sh
```

## What Gets Written

Canonical copies land in `~/.agents/skills/` (or `.agents/skills/` for
`--project`). Agents that don't read `.agents/skills` natively get mirrors —
only when detected (see [agent-paths.json](agent-paths.json) /
[skills/batho-setup/references/agent-matrix.md](skills/batho-setup/references/agent-matrix.md)
for the full matrix). An install receipt is written to
`~/.batho/skills-receipt.json`.

### Options

```text
--global | --project   scope (default: global → ~/.agents/skills)
--agent <name>         force a specific agent (repeatable)
--all                  write every known agent dir (skip detection)
--remove               uninstall the pack
--list                 dry-run: show targets
--copy                 copy instead of symlink for mirrors
--mcp                  also merge the batho MCP server into detected clients
-y, --yes              non-interactive
```

Env: `BATHO_VERSION`, `BATHO_INSTALL_DIR`, `BATHO_AGENTS`, `BATHO_COPY=1`,
`BATHO_SCOPE`, `BATHO_BASE_URL` (mirror/GHE override), `BATHO_NO_ANALYTICS=1`.

### Uninstall

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh | sh -s -- --remove
```

## Enterprise

Managed rollout (MDM/managed-settings snippets for Claude Code, Copilot,
Codex, Cursor), private/air-gapped install, and governance controls:
[docs/enterprise.md](docs/enterprise.md). Security/trust model:
[SECURITY.md](SECURITY.md). Install endpoints + telemetry service design:
[docs/install.md](docs/install.md) · [docs/telemetry/](docs/telemetry/README.md).

## Repo Layout

```
skills/<name>/SKILL.md          # the pack (agentskills.io format)
.claude-plugin/                 # Claude Code plugin + marketplace manifests
.agents/plugins/marketplace.json# Codex-native marketplace manifest
plugin.json + mcp.json          # Agent Plugins open standard (Cursor)
gemini-extension.json           # Gemini CLI extension
.mcp.json + hooks/              # Claude Code MCP + opt-in nudge hook
install.sh / install.ps1        # curl|sh / irm|iex installers
agent-paths.json                # per-agent discovery dirs (canonical table)
```

## License

MIT — see [LICENSE](LICENSE).
