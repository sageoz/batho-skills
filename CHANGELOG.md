# Changelog

## 1.0.0 (2026-09-19)

### Features

* Initial standalone release of the Batho skill pack: `batho`, `batho-setup`,
  `batho-specs`, `batho-execute`, `batho-review` extracted from
  [sageoz/Batho](https://github.com/sageoz/Batho).
* Multi-ecosystem packaging: Claude Code plugin + marketplace manifests,
  Codex marketplace (`.agents/plugins`), Agent Plugins open standard
  (`plugin.json` + `mcp.json`), Gemini CLI extension manifest.
* Cross-platform installers: POSIX `install.sh` and PowerShell
  `install.ps1` with sha256-verified downloads, per-agent detection, symlink
  mirrors, receipts, and `--remove`.
* `agent-paths.json` — canonical machine-readable table of 20+ agents' skill
  discovery directories.
