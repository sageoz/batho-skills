<div align="center">

# Batho-Skill-Pack

**Agent skills for [Batho](https://github.com/sageoz/Batho)**

[![validate](https://github.com/sageoz/batho-skills/actions/workflows/validate.yml/badge.svg)](https://github.com/sageoz/batho-skills/actions/workflows/validate.yml)
[![release](https://img.shields.io/github/v/release/sageoz/batho-skills)](https://github.com/sageoz/batho-skills/releases)
[![stars](https://img.shields.io/github/stars/sageoz/batho-skills?style=flat&logo=github&logoColor=white)](https://github.com/sageoz/batho-skills/stargazers)
[![agents](https://img.shields.io/badge/agents-22-4c1)](agent-paths.json)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

</div>

---

## Features

[Batho](https://github.com/sageoz/Batho) indexes your codebase into a **knowledge graph** and **Batho-Skill-Pack** guides your coding agent to query it through MCP. 

> "Graph grounded answers instead of grepping and guessing."

### Core capabilities

| Capability | Description |
|---|---|
| **Code graph** | Tree-sitter-parsed graph of every function, class, module, plus calls, imports, inheritance, and overrides |
| **MCP server** | Structural queries (`get_entity`, `trace_path`, `search_entities`) served from the graph artifact |
| **22-agent distribution** | Self-installing SKILL.md format with per-agent mirrors |
| **Full SDLC loop** | Specs → execute → review, graph-grounded at every stage |

### The SDLC loop

| Stage | Skill | What happens |
|---|---|---|
| **Setup** | `batho-setup` | One install targets 22 agents via per-agent mirrors |
| **Explore** | `batho` | "Who calls this?", "what breaks if I change X?" — answered from graph queries, not grep |
| **Specify** | `batho-specs` | Graph-grounded spec where every claim cites entities (`entity_id` + `file:line`) |
| **Implement** | `batho-execute` | Blast-radius-first, dependency-ordered tasks; every edit starts from the symbol's current signature |
| **Review** | `batho-review` | Per-criterion PASS/FAIL against the graph's change record — not raw diffs |

### Why it matters

- **Grounded answers** — structural questions resolved from the graph, not string search
- **Blast radius first** — impact analysis before every change drives risk-tiered task plans
- **Fresh by construction** — graph builds on first use, patches as you work, staleness-gated reads
- **Supply-chain safe** — deterministic, checksummed, SLSA-attested release artifacts

---

## Contents

- [Features](#features)
- [Install](#install)
- [Quick start](#quick-start)
- [The skill pack](#the-skill-pack)
- [Supported agents](#supported-agents)
- [Reference](#reference)
- [Enterprise](#enterprise)
- [Documentation](#documentation)
- [Repo layout](#repo-layout)
- [Contributing](#contributing)
- [License](#license)

---

## Install

**One command, every agent:**

```bash
npx skills add sageoz/batho-skills
```

The CLI detects which agents you have installed and writes each skill where
that agent looks.

<details>
<summary><strong>Other install methods</strong></summary>
<br>

**Claude Code (plugin marketplace)**

```bash
/plugin marketplace add sageoz/batho-skills
/plugin install batho@batho
```

**OpenAI Codex**

```bash
codex plugin marketplace add sageoz/batho-skills
```

**Gemini CLI**

```bash
gemini extensions install sageoz/batho-skills
```

**GitHub Copilot**

```bash
gh skills install sageoz/batho-skills
```

**curl installer (macOS / Linux / Git Bash / WSL)**

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh | sh
```

**PowerShell (Windows)**

```powershell
powershell -ExecutionPolicy Bypass -NoProfile -c "irm https://github.com/sageoz/batho-skills/releases/latest/download/install.ps1 | iex"
```

**Manual**

Copy `skills/<name>` into `<scope>/.agents/skills/` — every agent listed in
[agent-paths.json](agent-paths.json) reads from there or gets a mirror.

</details>

<details>
<summary><strong>Pin a version</strong></summary>
<br>

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/download/v1.0.0/install.sh | sh   # pinned URL
# or
BATHO_VERSION=1.0.0 sh -c "$(curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh)"
```

</details>

---

## Quick start

1. **Install the pack** — command above.

2. **Install the [Batho CLI](https://github.com/sageoz/Batho)** — the skills drive it.
   `batho-setup` can do this for you:

   ```bash
   curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install-batho.sh | sh   # macOS / Linux
   # Windows:
   powershell -ExecutionPolicy Bypass -NoProfile -c "irm https://github.com/sageoz/batho-skills/releases/latest/download/install-batho.ps1 | iex"
   # or directly: uv tool install batho (or pipx install batho)
   ```

3. **Open your repo and ask.** The `batho` skill builds and refreshes the graph
   on first use, then routes everything:

   ```text
   you: "Who calls connectToServer?"          → answered from the graph
   you: "Add dark mode to the settings page"
        batho-specs   → graph-grounded spec, every claim cited
        batho-execute → dependency-ordered tasks, pre-edit grounding
        batho-review  → per-criterion PASS/FAIL + structural delta
   ```

---

## The skill pack

| Skill | Purpose | Docs |
|---|---|---|
| `batho` | Router + artifact lifecycle — build/refresh the code graph, answer structural questions via MCP | [SKILL.md](skills/batho/SKILL.md) |
| `batho-setup` | Install the `batho` CLI, register the MCP server in your agent, install this pack | [SKILL.md](skills/batho-setup/SKILL.md) |
| `batho-specs` | Graph-grounded specifications — every claim cites entities from the code graph | [SKILL.md](skills/batho-specs/SKILL.md) |
| `batho-execute` | Spec-driven implementation — dependency-ordered tasks with pre-edit grounding | [SKILL.md](skills/batho-execute/SKILL.md) |
| `batho-review` | Graph-verified review — per-criterion PASS/FAIL with structural delta reports | [SKILL.md](skills/batho-review/SKILL.md) |

Plus a bundled `batho` MCP server registration (`mcp.json`, `.mcp.json`,
`gemini-extension.json`) and an opt-in nudge hook (`hooks/`, disabled by
default).

---

## Supported agents

22 agents are covered out of the box: Claude Code, Cursor, GitHub Copilot,
OpenAI Codex, Gemini CLI, OpenCode, Windsurf, Devin, Amp, Roo Code, Cline,
Zed, Kiro, Factory Droid, Trae, Google Antigravity, JetBrains Junie, Goose,
Warp, Pi, Continue, and Kilo Code.

Canonical copies land in `~/.agents/skills/` (global) or `.agents/skills/`
(project); agents that don't read that path natively get mirrors — only when
detected.

- Full per-agent discovery table: [agent-paths.json](agent-paths.json)
- Install matrix and mirror behavior:
  [skills/batho-setup/references/agent-matrix.md](skills/batho-setup/references/agent-matrix.md)

---

## Reference

<details>
<summary><strong>What gets written</strong></summary>
<br>

Canonical copies land in `~/.agents/skills/` (or `.agents/skills/` for
`--project`). Agents that don't read `.agents/skills` natively get mirrors —
only when detected (see [agent-paths.json](agent-paths.json) /
[skills/batho-setup/references/agent-matrix.md](skills/batho-setup/references/agent-matrix.md)
for the full matrix). An install receipt is written to
`~/.batho/skills-receipt.json`.

</details>

<details>
<summary><strong>Verify before running</strong></summary>
<br>

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

See also [SECURITY.md](SECURITY.md).

</details>

<details>
<summary><strong>Installer options & environment</strong></summary>
<br>

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

**Uninstall:**

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh | sh -s -- --remove
```

</details>

---

## Enterprise

Managed rollout (MDM / managed-settings snippets for Claude Code, Copilot,
Codex, Cursor), private/air-gapped install, and governance controls —
see [docs/enterprise.md](docs/enterprise.md).

---

## Documentation

| Doc | Covers |
|---|---|
| [docs/enterprise.md](docs/enterprise.md) | Managed rollout, air-gapped install, governance |
| [docs/install.md](docs/install.md) | Install endpoints + installer design |
| [SECURITY.md](SECURITY.md) | Security & trust model |
| [CHANGELOG.md](CHANGELOG.md) | Release history |

---

## Repo layout

```
skills/<name>/SKILL.md           # the pack (agentskills.io format)
.claude-plugin/                  # Claude Code plugin + marketplace manifests
.agents/plugins/marketplace.json # Codex-native marketplace manifest
plugin.json + mcp.json           # Agent Plugins open standard (Cursor)
gemini-extension.json            # Gemini CLI extension
.mcp.json + hooks/               # Claude Code MCP + opt-in nudge hook
install.sh / install.ps1         # curl|sh / irm|iex installers
agent-paths.json                 # per-agent discovery dirs (canonical table)
```

---

## Contributing

PRs welcome. Skills follow the [Agent Skills](https://agentskills.io) format
(`skills/<name>/SKILL.md`); CI validates every change — see
[.github/workflows/validate.yml](.github/workflows/validate.yml).

---

## License

MIT — see [LICENSE](LICENSE).
