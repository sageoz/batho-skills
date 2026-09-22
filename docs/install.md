# Install endpoints

Two installers, both served straight from GitHub Releases — GitHub is the
artifact store and the distribution layer (no vanity domain, no redirect
layer).

## Asset map

| Release asset | Installs | Purpose |
|---|---|---|
| `install-batho.sh` / `install-batho.ps1` | `batho` CLI via uv | **Batho CLI** |
| `install.sh` / `install.ps1` | skill pack (this repo) | **skill pack** |
| `batho-skills-<X.Y.Z>.tar.gz` / `.zip` | pack payload | consumed by the installers |
| `sha256sums.txt` | checksums | integrity verification |

Latest:

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh | sh
```

Pinned:

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/download/v1.0.0/install.sh | sh
```

Scripts ship as GitHub Release assets — versioned, immutable, checksummed
(`sha256sums.txt`), SLSA-attested. `install.sh`/`install.ps1` for the skill
pack embed the payload SHA256 at release-render time; the CLI installers
delegate integrity to PyPI/uv (hashes verified by the package index).

## CLI installer (`install-batho.sh` / `.ps1`)

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install-batho.sh | sh
```

What it does: detect platform → install `uv` if missing
(`https://astral.sh/uv/install.sh`, overridable via `UV_URL`) →
`uv tool install batho` → next-steps output. User-writable paths only, no
sudo, POSIX sh / PowerShell, function-wrapped + `main`-last so a truncated
download executes nothing. `--version`/`-y`/`--help`; upgrade-aware
(`uv tool upgrade`).

## Skill-pack installer (`install.sh` / `install.ps1`)

```bash
curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh | sh
```

Downloads the release tarball → verifies embedded SHA256 → writes canonical
copies to `~/.agents/skills/` (or `.agents/skills` with `--project`) →
symlink mirrors for detected non-`.agents` readers → receipt at
`~/.batho/skills-receipt.json`. Flags: `--global|--project --agent --all
--remove --list --copy --mcp -y`. See [README.md](../README.md).

## Rollback

Rollback is GitHub-side: repoint the "latest" release to the previous tag.
No infrastructure to roll back — releases are the only serving layer.
