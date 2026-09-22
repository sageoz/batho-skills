# Enterprise deployment — managed rollout, airgap, governance

This pack is designed for managed environments: it ships as an immutable
GitHub Release (checksums + SLSA attestations), installs to user-writable
paths only (no sudo), and is consumable through each vendor's enterprise
control plane.

## Push to a fleet (managed settings)

### Claude Code

Deploy `managed-settings.json` via MDM (macOS `/Library/Application
Support/ClaudeCode/managed-settings.json`, Linux `/etc/claude-code/`,
Windows `C:\Program Files\ClaudeCode\`, or Jamf/Intune/GPO templates):

```json
{
  "extraKnownMarketplaces": {
    "batho": { "source": { "source": "github", "repo": "sageoz/batho-skills" } }
  },
  "enabledPlugins": { "batho@batho": true },
  "strictKnownMarketplaces": [
    { "source": "github", "repo": "sageoz/batho-skills" }
  ]
}
```

`enabledPlugins` force-installs at managed scope (users can't remove).
`strictKnownMarketplaces` is an allowlist — `[]` locks down entirely.

Known issues to plan around (upstream bugs, current as of Sep 2026):
- Private-repo `marketplace add` can ignore credential helpers / GITHUB_TOKEN
  (anthropics/claude-code#17201, #49694) — use SSH (`git@host:org/repo.git`)
  or pre-clone to `~/.claude/plugins/marketplaces/` and add the local path.
- `extraKnownMarketplaces` inside `managed-settings.json` is ignored by bug
  #16870 — prefer project `.claude/settings.json` or file-scope managed paths.
- `autoUpdate` refreshes the catalog but does not reinstall plugin files
  (#61854) — fleet updates should run `/plugin marketplace update`.

### GitHub Copilot

Server-managed settings via a `.github-private` repo in the org containing
`copilot/managed-settings.json` (+ `copilot/team-mappings.json` for per-team
overrides) — same key names: `extraKnownMarketplaces`, `enabledPlugins`,
`strictKnownMarketplaces`.

### OpenAI Codex

- Admin allowlist: `/etc/codex/requirements.toml` (or
  `%ProgramData%\OpenAI\Codex\requirements.toml` on Windows):

```toml
[marketplaces]
restrict_to_allowed_sources = true

[marketplaces.allowed_sources.batho]
type = "git"
url = "https://github.com/sageoz/batho-skills.git"
```

- Machine-wide skills drop-in: `/etc/codex/skills/` (admin scope).
- ChatGPT workspace admins: Admin → Plugins → import marketplace from GitHub
  (daily sync, per-plugin install policy, CSV export for security review).

### Cursor

Dashboard → Plugins → Team Marketplaces → import `sageoz/batho-skills`.
Distribution modes: Default Off / Default On / Required. Enterprise plans get
unlimited admin-only marketplaces; audit log is Enterprise-only.

## Air-gapped / internal mirror

No git or external network needed on endpoints:

1. Download once, on a connected machine:
   ```
   gh release download vX.Y.Z --repo sageoz/batho-skills \
     --pattern 'batho-skills-*.zip' --pattern 'sha256sums.txt'
   sha256sum --check sha256sums.txt
   ```
2. Host the zip + sums on internal HTTPS.
3. Register an internal marketplace whose plugin source is the archive:

```json
{
  "name": "internal",
  "owner": { "name": "Platform Team" },
  "plugins": [{
    "name": "batho",
    "source": {
      "source": "archive",
      "url": "https://artifacts.internal/batho/batho-skills-X.Y.Z.zip",
      "sha256": "<digest from sha256sums.txt>"
    }
  }]
}
```

or vendor the repo to an internal path and use a `file`-type marketplace
source. `BATHO_BASE_URL=https://artifacts.internal/...` also repoints the
shell/PowerShell installers at your mirror.

## What to audit (we ship this checklist for reviewers)

- Every `skills/*/SKILL.md` body — natural-language instructions, diff each
  release.
- `.mcp.json` / `mcp.json` — registers stdio `batho mcp`; review the batho
  binary's own supply chain (PyPI release + checksums).
- `hooks/hooks.json` — opt-in, echo-only nudge; disabled by default.
- `install.sh` / `install.ps1` — readable scripts; checksum-verify before run.
- `agent-paths.json` — complete list of dirs the installer may write.

## Governance notes

- Skills carry no signing standard yet (spec RFC pending); trust today =
  immutable releases + sha256 + SLSA attestations + marketplace allowlists.
- Update policy: the pack never self-updates; users/fleets pull new versions
  explicitly (installer pin or `/plugin marketplace update`).
