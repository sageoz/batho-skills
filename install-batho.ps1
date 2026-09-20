# Batho CLI installer for Windows — installs uv (if needed) then `uv tool install batho`.
#
#   powershell -ExecutionPolicy Bypass -NoProfile -c "irm https://github.com/sageoz/batho-skills/releases/latest/download/install-batho.ps1 | iex"
#
# Configure via env vars (irm|iex cannot forward args):
#   $env:BATHO_VERSION="1.4.2"   # pin a version
#   $env:UV_URL="https://mirror/uv/install.ps1"   # uv installer mirror override
# Or pass args via scriptblock:
#   iex "& {$(irm https://github.com/sageoz/batho-skills/releases/latest/download/install-batho.ps1)} -Version 1.4.2"

[CmdletBinding()]
param(
    [string]$Version = $env:BATHO_VERSION,
    [string]$UvUrl = $(if ($env:UV_URL) { $env:UV_URL } else { 'https://astral.sh/uv/install.ps1' })
)

$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

function Test-Cmd { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

if (-not (Test-Cmd uv)) {
    Write-Host "batho-install: uv not found — installing via $UvUrl"
    Invoke-Expression "& {$(Invoke-RestMethod $UvUrl)}"
    # uv installs to $env:USERPROFILE\.local\bin — refresh PATH for this session
    $uvBin = Join-Path $env:USERPROFILE '.local\bin'
    if (Test-Path (Join-Path $uvBin 'uv.exe')) { $env:PATH = "$uvBin;$env:PATH" }
}
if (-not (Test-Cmd uv)) {
    Write-Host "batho-install: uv installed but not on PATH — restart your shell, then run: uv tool install batho"
    return
}

$spec = if ($Version) { "batho==$Version" } else { 'batho' }
if (Test-Cmd batho) {
    Write-Host "batho-install: batho present — upgrading"
    uv tool upgrade batho
    if ($LASTEXITCODE -ne 0) { uv tool install --force $spec }
} else {
    uv tool install $spec
}
if ($LASTEXITCODE -ne 0) { throw "uv tool install failed" }

Write-Host ""
Write-Host "batho is ready. Next:"
Write-Host "  batho mcp          # stdio MCP server (register in your agent's config)"
Write-Host "  batho build        # build a code-graph artifact for a repo"
Write-Host "Skill pack: irm https://github.com/sageoz/batho-skills/releases/latest/download/install.ps1 | iex"
