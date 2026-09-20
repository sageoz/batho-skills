# Security Policy

## What this pack executes

| Surface | What runs | Notes |
|---|---|---|
| `skills/*/SKILL.md` | Natural-language instructions to the agent | Reviewed like code; diff every release |
| `.mcp.json` / `mcp.json` | `batho mcp` — local stdio MCP server | Requires the `batho` CLI (PyPI: `uv tool install batho`) |
| `hooks/hooks.json` | An echo-only "nudge" on the Grep tool | **Opt-in, disabled by default** — the file must be manually moved into settings to activate |
| `install.sh` / `install.ps1` | Download → sha256-verify → extract → write skill dirs | User-writable paths only, never sudo |
| `agent-paths.json` | Data table of agent skill dirs | No code |

## Verifying a release

All release artifacts are deterministic and attested:

```bash
gh release download vX.Y.Z --repo sageoz/batho-skills
sha256sum --check sha256sums.txt
gh attestation verify <artifact> --repo sageoz/batho-skills
```

The rendered `install.sh` for a given tag embeds that tag's payload SHA256 —
the single script download pins the payload it installs.

## Trust model

- **Immutable releases**: tags and assets cannot be modified after publish.
- **No auto-update**: the pack never updates itself; installs are explicit.
- **Least privilege**: installers write only user/project skill dirs; no
  sudo, no shell-profile edits, no persistence mechanisms.
- **Transparency**: the installer is a readable POSIX script — inspect with
  `curl -fsSL <url> | less` before piping to `sh`.

## Reporting a vulnerability

Use GitHub private vulnerability reporting on this repository
(Security → Advisories → "Report a vulnerability"). Do not file public
issues for unpatched vulnerabilities.

## Scope

In scope: the skill-pack contents, the installers, the manifests, the release
pipeline, and the `batho` MCP registration surface. Out of scope: the `batho`
CLI itself — report those on [sageoz/Batho](https://github.com/sageoz/Batho).
