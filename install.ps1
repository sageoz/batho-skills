# Batho skill pack installer — Windows PowerShell.
#
#   powershell -ExecutionPolicy Bypass -NoProfile -c "irm https://github.com/sageoz/batho-skills/releases/latest/download/install.ps1 | iex"
#
# irm|iex cannot forward arguments — configure via env vars set before the pipe:
#   $env:BATHO_VERSION="1.0.0"   # pin a release (default: latest)
#   $env:BATHO_SCOPE="project"   # default: global (%USERPROFILE%\.agents\skills)
#   $env:BATHO_AGENTS="claude-code kiro"   # force agents (space-separated)
#   $env:BATHO_ALL="1"           # write every known agent dir (skip detection)
#   $env:BATHO_REMOVE="1"        # uninstall pack skills
#   $env:BATHO_COPY="1"          # copy instead of junction/symlink mirrors
#   $env:BATHO_INSTALL_DIR="D:\path"       # override all target roots
#   $env:BATHO_BASE_URL="https://mirror/…" # custom release host (default: github.com)
#
# Or pass args via scriptblock:  iex "& {$(irm https://github.com/sageoz/batho-skills/releases/latest/download/install.ps1)} -Version 1.0.0"
#
# Generated releases embed the expected SHA256 of the payload below.

[CmdletBinding()]
param(
    [string]$Version = $env:BATHO_VERSION,
    [string]$Scope = $(if ($env:BATHO_SCOPE) { $env:BATHO_SCOPE } else { 'global' }),
    [string]$Agents = $env:BATHO_AGENTS,
    [string]$InstallDir = $env:BATHO_INSTALL_DIR,
    [string]$BaseUrl = $(if ($env:BATHO_BASE_URL) { $env:BATHO_BASE_URL } else { 'https://github.com/sageoz/batho-skills/releases' }),
    [switch]$All = [bool]$env:BATHO_ALL,
    [switch]$Remove = [bool]$env:BATHO_REMOVE,
    [switch]$List = [bool]$env:BATHO_LIST,
    [switch]$Copy = [bool]$env:BATHO_COPY,
    [switch]$Yes = ([bool]$env:NONINTERACTIVE -or [bool]$env:CI)
)

$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$PackSkills = @('batho', 'batho-setup', 'batho-specs', 'batho-execute', 'batho-review')
$ReceiptDir  = if ($env:BATHO_RECEIPT_DIR) { $env:BATHO_RECEIPT_DIR } else { Join-Path $env:USERPROFILE '.batho' }
$Receipt     = Join-Path $ReceiptDir 'skills-receipt.json'

# Filled by the release renderer; empty in the repo template = resolve at runtime.
$EmbeddedVersion = '@@BATHO_VERSION@@'
$EmbeddedSha256  = '@@SHA256_ZIP@@'
if ($EmbeddedVersion -eq '@@BATHO_VERSION@@') { $EmbeddedVersion = '' }
if ($EmbeddedSha256  -eq '@@SHA256_ZIP@@')    { $EmbeddedSha256  = '' }

# GENERATED TABLE — keep in sync with agent-paths.json (CI checks parity).
# id | reads_agents(0/1) | detect_global_dirs | detect_project_dirs | bins | project_dirs | global_dirs
$AgentTable = @'
claude-code|0|%USERPROFILE%\.claude|.claude|claude|.claude\skills|%USERPROFILE%\.claude\skills
cursor|1|%USERPROFILE%\.cursor|.cursor|cursor|.cursor\skills|%USERPROFILE%\.cursor\skills
copilot|1|%USERPROFILE%\.copilot|.github|copilot|.github\skills|%USERPROFILE%\.copilot\skills
codex|1|%USERPROFILE%\.codex|.codex|codex|.codex\skills|%USERPROFILE%\.codex\skills
gemini|1|%USERPROFILE%\.gemini|.gemini|gemini|.gemini\skills|%USERPROFILE%\.gemini\skills
opencode|1|%APPDATA%\opencode|.opencode|opencode|.opencode\skills|%APPDATA%\opencode\skills
windsurf|1|%USERPROFILE%\.codeium|.windsurf|windsurf|.windsurf\skills|%APPDATA%\Windsurf\skills
devin|1|%APPDATA%\devin|.devin|devin|.devin\skills|%APPDATA%\devin\skills
amp|1|%APPDATA%\amp||amp||%APPDATA%\amp\skills
roo|1|%USERPROFILE%\.roo|.roo||.roo\skills|%USERPROFILE%\.roo\skills
cline|0|%USERPROFILE%\.cline|.cline||.cline\skills|%USERPROFILE%\.cline\skills
zed|1|%USERPROFILE%\.zed|.zed|zed||
kiro|0|%USERPROFILE%\.kiro|.kiro|kiro|.kiro\skills|%USERPROFILE%\.kiro\skills
factory|0|%USERPROFILE%\.factory|.factory|droid|.factory\skills|%USERPROFILE%\.factory\skills
trae|0|%USERPROFILE%\.trae|.trae||.trae\skills|%USERPROFILE%\.trae\skills
antigravity|1|%USERPROFILE%\.gemini\antigravity||agy|.agent\skills|%USERPROFILE%\.gemini\antigravity\skills,%USERPROFILE%\.gemini\config\skills
junie|0|%USERPROFILE%\.junie|.junie|junie|.junie\skills|%USERPROFILE%\.junie\skills
goose|1|%APPDATA%\Block\goose|.goose|goose|.goose\skills|%APPDATA%\Block\goose\skills
warp|1|%USERPROFILE%\.warp|.warp||.warp\skills|%USERPROFILE%\.warp\skills
pi|1|%USERPROFILE%\.pi|.pi|pi|.pi\skills|%USERPROFILE%\.pi\agent\skills
continue|0|%USERPROFILE%\.continue|.continue||.continue\skills|%USERPROFILE%\.continue\skills
kilocode|0|%USERPROFILE%\.kilocode|.kilocode||.kilocode\skills|%USERPROFILE%\.kilocode\skills
'@

function Write-Info { param([string]$Msg) Write-Host "batho-install: $Msg" }
function Expand-AgentPath {
    param([string]$Path)
    # expand %VAR% env-var syntax
    return [Environment]::ExpandEnvironmentVariables($Path)
}
function Split-Csv { param([string]$Csv) if ($Csv) { $Csv -split ',' } }

$script:AgentIndex = @{}
foreach ($line in ($AgentTable -split "`n")) {
    $line = $line.Trim()
    if (-not $line) { continue }
    $f = $line -split '\|', 7
    $script:AgentIndex[$f[0]] = @{
        ReadsAgents = ($f[1] -eq '1'); DetectG = $f[2]; DetectP = $f[3]
        Bins = $f[4]; PDirs = $f[5]; GDirs = $f[6]
    }
}

function Test-AgentDetected {
    param([string]$Id, [string]$ProjectRoot)
    $a = $script:AgentIndex[$Id]
    foreach ($m in (Split-Csv $a.DetectG)) { if (Test-Path (Expand-AgentPath $m)) { return $true } }
    foreach ($m in (Split-Csv $a.DetectP)) { if (Test-Path (Join-Path $ProjectRoot $m)) { return $true } }
    foreach ($b in (Split-Csv $a.Bins)) { if (Get-Command $b -ErrorAction SilentlyContinue) { return $true } }
    return $false
}

function Install-One {
    param([string]$Src, [string]$Dst, [bool]$AsCopy)
    if (Test-Path $Dst) {
        $item = Get-Item $Dst -Force
        if ($item.LinkType -and $item.Target -eq $Src) { return 'link(ok)' }
        Remove-Item $Dst -Recurse -Force
    }
    if ($AsCopy) {
        Copy-Item $Src $Dst -Recurse; return 'copied'
    }
    try {
        New-Item -ItemType Junction -Path $Dst -Target $Src -ErrorAction Stop | Out-Null
        return 'linked'
    } catch {
        try {
            New-Item -ItemType SymbolicLink -Path $Dst -Target $Src -ErrorAction Stop | Out-Null
            return 'linked'
        } catch {
            Copy-Item $Src $Dst -Recurse; return 'copied'
        }
    }
}

function Remove-One {
    param([string]$Dst)
    if (-not (Test-Path $Dst)) { return 'absent' }
    $item = Get-Item $Dst -Force
    if ($item.LinkType) { Remove-Item $Dst -Force; return 'removed(link)' }
    if ($item.PSIsContainer) {
        if (Test-Path (Join-Path $Dst '.batho-skill')) { Remove-Item $Dst -Recurse -Force; return 'removed(copy)' }
        return 'skipped(not-ours)'
    }
    Remove-Item $Dst -Force; return 'removed'
}

function Write-Receipt {
    param([string]$Ver, [string]$Scp, [string[]]$Dirs)
    New-Item -ItemType Directory -Force -Path $ReceiptDir | Out-Null
    @{ pack = 'batho'; version = $Ver; scope = $Scp
       installed_at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
       dirs = $Dirs } | ConvertTo-Json -Depth 4 | Set-Content $Receipt -Encoding UTF8
}

function Get-Pack {
    param([string]$DestDir)
    $ver = if ($Version) { $Version } elseif ($EmbeddedVersion) { $EmbeddedVersion } else { 'latest' }
    if ($ver -notmatch '^v' -and $ver -ne 'latest') { $ver = "v$ver" }
    if ($ver -eq 'latest') {
        $zipUrl  = "$BaseUrl/latest/download/batho-skills.zip"
        $sumsUrl = "$BaseUrl/latest/download/sha256sums.txt"
        $asset   = 'batho-skills.zip'
    } else {
        $noV = $ver -replace '^v', ''
        $zipUrl  = "$BaseUrl/download/$ver/batho-skills-$noV.zip"
        $sumsUrl = "$BaseUrl/download/$ver/sha256sums.txt"
        $asset   = "batho-skills-$noV.zip"
    }
    Write-Info "fetching $zipUrl"
    $zipPath = Join-Path $DestDir 'pack.zip'
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

    $expected = $EmbeddedSha256
    if (-not $expected) {
        $sumsPath = Join-Path $DestDir 'sha256sums.txt'
        Invoke-WebRequest -Uri $sumsUrl -OutFile $sumsPath -UseBasicParsing
        $line = Get-Content $sumsPath | Where-Object { $_ -match [regex]::Escape($asset) } | Select-Object -First 1
        if (-not $line) { $line = Get-Content $sumsPath | Select-Object -First 1 }
        $expected = ($line -split '\s+')[0]
    }
    $actual = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected.ToLowerInvariant()) {
        throw "checksum mismatch for pack zip (expected $expected, got $actual) - aborting"
    }
    Write-Info "sha256 verified ($actual)"

    $extractDir = Join-Path $DestDir 'extract'
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
    $skillsDir = Get-ChildItem -Path $extractDir -Recurse -Directory -Filter 'skills' | Select-Object -First 1
    if (-not $skillsDir) { throw 'archive did not contain a skills/ directory' }
    return $skillsDir.FullName
}

# ---- main -----------------------------------------------------------------

$ProjectRoot = (Get-Location).Path
if ($InstallDir) {
    $canonical = Expand-AgentPath $InstallDir
} elseif ($Scope -eq 'global') {
    $canonical = Join-Path $env:USERPROFILE '.agents\skills'
} else {
    $canonical = Join-Path $ProjectRoot '.agents\skills'
}

# Build target list: canonical + mirrors for detected/forced non-readers.
$targets = [System.Collections.Generic.List[object]]::new()
if ($InstallDir) {
    $targets.Add(@('custom', $canonical))
} else {
    $targets.Add(@('canonical', $canonical))
    $forced = @()
    if ($Agents) { $forced = $Agents -split '\s+' }
    foreach ($id in $script:AgentIndex.Keys) {
        $isForced = $forced -contains $id
        if (-not $All -and -not $isForced -and -not (Test-AgentDetected $id $ProjectRoot)) { continue }
        $a = $script:AgentIndex[$id]
        if (-not $a.ReadsAgents -or $isForced -or $All) {
            $native = if ($Scope -eq 'global') { $a.GDirs } else { $a.PDirs }
            foreach ($d in (Split-Csv $native)) {
                $d = Expand-AgentPath $d
                if ($Scope -eq 'project') { $d = Join-Path $ProjectRoot $d }
                $targets.Add(@($id, $d))
            }
        }
    }
}

if ($List) {
    Write-Info "targets ($($targets.Count) scope roots):"
    foreach ($t in $targets) {
        foreach ($s in $PackSkills) { Write-Host ("  {0,-14} {1}" -f $t[0], (Join-Path $t[1] $s)) }
    }
    return
}

if ($Remove) {
    foreach ($t in $targets) {
        foreach ($s in $PackSkills) {
            $st = Remove-One (Join-Path $t[1] $s)
            Write-Host ("{0,-18} {1}:{2}" -f $st, $t[0], (Join-Path $t[1] $s))
        }
    }
    if (Test-Path $Receipt) { Remove-Item $Receipt -Force }
    Write-Info 'remove complete'
    return
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("batho-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    $srcSkills = Get-Pack $tmp

    foreach ($t in $targets) {
        $agent = $t[0]; $dir = $t[1]
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        foreach ($s in $PackSkills) {
            $src = Join-Path $srcSkills $s
            if (-not (Test-Path $src)) { Write-Info "missing skill in archive: $s"; continue }
            # canonical/custom hold real files; mirrors link to the canonical copy
            if ($agent -eq 'canonical' -or $agent -eq 'custom') {
                $st = Install-One $src (Join-Path $dir $s) $true
            } else {
                $st = Install-One (Join-Path $canonical $s) (Join-Path $dir $s) $Copy
            }
            $dstSkill = Join-Path $dir $s
            if ((Test-Path $dstSkill) -and -not (Get-Item $dstSkill -Force).LinkType) {
                New-Item -ItemType File -Force -Path (Join-Path $dstSkill '.batho-skill') | Out-Null
            }
            Write-Host ("{0,-10} {1}:{2}" -f $st, $agent, $dstSkill)
        }
    }

    $written = $targets | ForEach-Object { $_[1] } | Sort-Object -Unique
    Write-Receipt ($ver = if ($Version) { $Version } else { 'latest' }) $Scope $written
    Write-Info "receipt written to $Receipt"
    Write-Info 'done - restart your agent(s) to pick up the skills'
} finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
