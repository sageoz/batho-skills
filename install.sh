#!/bin/sh
# Batho skill pack installer — POSIX sh.
#
#   curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh | sh
#
# Options (as flags via `sh -s -- ...` or env vars):
#   --global | --project     install scope (default: global → ~/.agents/skills)
#   --agent <name>           force a specific agent (repeatable)
#   --all                    write every known agent's dirs (no detection)
#   --remove                 uninstall pack skills
#   --list                   show what would be written, then exit
#   --copy                   copy instead of symlink for mirrors
#   --mcp                    also merge the batho MCP server into detected clients
#   -y, --yes                non-interactive (also: NONINTERACTIVE=1 / CI=1)
#   -h, --help               show help
#
# Env: BATHO_VERSION (pin, e.g. 1.0.0 or v1.0.0), BATHO_INSTALL_DIR (override
# all target roots), BATHO_AGENTS (space-separated agent ids), BATHO_COPY=1,
# BATHO_SCOPE=global|project, BATHO_NO_ANALYTICS=1.
#
# Generated releases embed the expected SHA256 of the payload below; the
# repo version resolves sha256sums.txt from the matching release instead.
#
# GENERATED TABLE — keep in sync with agent-paths.json (CI checks parity).

set -eu

BATHO_REPO="sageoz/batho-skills"
BATHO_BASE_URL="${BATHO_BASE_URL:-https://github.com/${BATHO_REPO}/releases}"
PACK_SKILLS="batho batho-setup batho-specs batho-execute batho-review"
RECEIPT_DIR="${BATHO_RECEIPT_DIR:-$HOME/.batho}"
RECEIPT="$RECEIPT_DIR/skills-receipt.json"
# shellcheck disable=SC2034  # populated at first signed release
MINISIG_PUB=""

# Filled by the release renderer (T11); empty in the repo template = resolve at runtime.
EMBEDDED_VERSION="@@BATHO_VERSION@@"
EMBEDDED_SHA256="@@SHA256_TAR@@"
[ "$EMBEDDED_VERSION" = "@@BATHO_VERSION@@" ] && EMBEDDED_VERSION=""
[ "$EMBEDDED_SHA256" = "@@SHA256_TAR@@" ] && EMBEDDED_SHA256=""

# id|reads_agents(0/1)|detect_global_dirs|detect_project_dirs|bins|project_dirs|global_dirs
# lists are comma-separated; ~ expands to $HOME at runtime
AGENT_TABLE='claude-code|0|~/.claude|.claude|claude|.claude/skills|~/.claude/skills
cursor|1|~/.cursor|.cursor|cursor|.cursor/skills|~/.cursor/skills
copilot|1|~/.copilot|.github|copilot|.github/skills|~/.copilot/skills
codex|1|~/.codex|.codex|codex|.codex/skills|~/.codex/skills
gemini|1|~/.gemini|.gemini|gemini|.gemini/skills|~/.gemini/skills
opencode|1|~/.config/opencode|.opencode|opencode|.opencode/skills|~/.config/opencode/skills
windsurf|1|~/.codeium|.windsurf|windsurf|.windsurf/skills|~/.codeium/windsurf/skills
devin|1|~/.config/devin|.devin|devin|.devin/skills|~/.config/devin/skills
amp|1|~/.config/amp||amp||~/.config/agents/skills,~/.config/amp/skills
roo|1|~/.roo|.roo||.roo/skills|~/.roo/skills
cline|0|~/.cline|.cline||.cline/skills|~/.cline/skills
zed|1|~/.zed|.zed|zed||
kiro|0|~/.kiro|.kiro|kiro|.kiro/skills|~/.kiro/skills
factory|0|~/.factory|.factory|droid|.factory/skills|~/.factory/skills
trae|0|~/.trae|.trae||.trae/skills|~/.trae/skills
antigravity|1|~/.gemini/antigravity||agy|.agent/skills|~/.gemini/antigravity/skills,~/.gemini/config/skills,~/.gemini/antigravity-cli/skills
junie|0|~/.junie|.junie|junie|.junie/skills|~/.junie/skills
goose|1|~/.config/goose|.goose|goose|.goose/skills|~/.config/goose/skills
warp|1|~/.warp|.warp||.warp/skills|~/.warp/skills
pi|1|~/.pi|.pi|pi|.pi/skills|~/.pi/agent/skills
continue|0|~/.continue|.continue||.continue/skills|~/.continue/skills
kilocode|0|~/.kilocode|.kilocode||.kilocode/skills|~/.kilocode/skills'

say()  { printf '%s\n' "$*"; }
warn() { printf 'batho-install: %s\n' "$*" >&2; }
err()  { warn "$*"; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || err "required command not found: $1"; }

expand_path() {
    # expand leading ~ to $HOME
    # shellcheck disable=SC2088  # intentional literal-tilde pattern match
    case $1 in
        "~/"*) printf '%s/%s\n' "$HOME" "${1#"~/"}" ;;
        *)     printf '%s\n' "$1" ;;
    esac
}

split_csv() {
    # print each comma-separated item on its own line
    _csv=$1
    [ -n "$_csv" ] || return 0
    _oldifs=$IFS; IFS=','
    # shellcheck disable=SC2086
    for _p in $_csv; do printf '%s\n' "$_p"; done
    IFS=$_oldifs
}

downloader() {
    if command -v curl >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -fsSL "$1"
    elif command -v wget >/dev/null 2>&1; then
        wget --https-only --secure-protocol=TLSv1_2 -qO- "$1"
    elif command -v fetch >/dev/null 2>&1; then
        fetch -qo- "$1"
    else
        err "need curl, wget, or fetch"
    fi
}

download_to() {
    _url=$1; _out=$2
    if command -v curl >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -fsSL "$_url" -o "$_out"
    elif command -v wget >/dev/null 2>&1; then
        wget --https-only --secure-protocol=TLSv1_2 -qO "$_out" "$_url"
    elif command -v fetch >/dev/null 2>&1; then
        fetch -qo "$_out" "$_url"
    else
        err "need curl, wget, or fetch"
    fi
}

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 "$1" | awk '{print $NF}'
    else
        err "need sha256sum, shasum, or openssl for integrity verification"
    fi
}

agent_field() {
    # agent_field <id> <col>  (1=id 2=reads_agents 3=detect_g 4=detect_p 5=bins 6=pdirs 7=gdirs)
    printf '%s\n' "$AGENT_TABLE" | while IFS='|' read -r _id _ra _dg _dp _b _pd _gd; do
        if [ "$_id" = "$1" ]; then
            case $2 in
                2) printf '%s' "$_ra" ;; 3) printf '%s' "$_dg" ;;
                4) printf '%s' "$_dp" ;; 5) printf '%s' "$_b" ;;
                6) printf '%s' "$_pd" ;; 7) printf '%s' "$_gd" ;;
            esac
            return 0
        fi
    done
}

agent_known() {
    printf '%s\n' "$AGENT_TABLE" | while IFS='|' read -r _id _rest; do
        [ "$_id" = "$1" ] && return 0
    done
    return 1
}

agent_detected() {
    _id=$1; _proot=$2
    for _m in $(agent_field "$_id" 3 | tr ',' ' '); do
        [ -d "$(expand_path "$_m")" ] && return 0
    done
    for _m in $(agent_field "$_id" 4 | tr ',' ' '); do
        [ -d "$_proot/$_m" ] && return 0
    done
    for _b in $(agent_field "$_id" 5 | tr ',' ' '); do
        command -v "$_b" >/dev/null 2>&1 && return 0
    done
    return 1
}

agent_ids() { printf '%s\n' "$AGENT_TABLE" | cut -d'|' -f1; }

# ---- install primitives -------------------------------------------------

install_one() { # src dst copy(0/1) → prints status
    _src=$1; _dst=$2; _copy=$3
    if [ -L "$_dst" ]; then
        if [ "$(readlink "$_dst")" = "$_src" ]; then printf 'link(ok)'; return 0; fi
        rm -f "$_dst"
    elif [ -d "$_dst" ]; then
        rm -rf "$_dst"
    fi
    if [ "$_copy" = "1" ]; then
        cp -R "$_src" "$_dst"; printf 'copied'; return 0
    fi
    if ln -s "$_src" "$_dst" 2>/dev/null; then printf 'linked'; else cp -R "$_src" "$_dst"; printf 'copied'; fi
}

remove_one() { # dst — only removes symlinks we made or dirs with our marker
    _dst=$1
    if [ -L "$_dst" ]; then rm -f "$_dst"; printf 'removed(link)'; return 0; fi
    if [ -d "$_dst" ]; then
        if [ -f "$_dst/.batho-skill" ]; then rm -rf "$_dst"; printf 'removed(copy)'; else printf 'skipped(not-ours)'; fi
        return 0
    fi
    printf 'absent'
}

write_receipt() { # version scope
    mkdir -p "$RECEIPT_DIR"
    {
        printf '{\n  "pack": "batho",\n  "version": "%s",\n  "scope": "%s",\n' "$1" "$2"
        printf '  "installed_at": "%s",\n  "dirs": [' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        _first=1
        for _d in $WRITTEN_DIRS; do
            [ $_first -eq 0 ] && printf ','
            printf '\n    "%s"' "$_d"; _first=0
        done
        printf '\n  ]\n}\n'
    } > "$RECEIPT"
}

# ---- payload fetch ------------------------------------------------------

resolve_version() {
    if [ -n "${BATHO_VERSION:-}" ]; then
        case $BATHO_VERSION in v*) printf '%s' "$BATHO_VERSION" ;; *) printf 'v%s' "$BATHO_VERSION" ;; esac
        return 0
    fi
    if [ -n "$EMBEDDED_VERSION" ]; then printf '%s' "$EMBEDDED_VERSION"; return 0; fi
    printf 'latest'
}

fetch_pack() { # dest-dir — downloads + verifies + extracts skills into $1/skills
    _dest=$1
    _ver=$(resolve_version)
    if [ "$_ver" = "latest" ]; then
        _tgz_url="$BATHO_BASE_URL/latest/download/batho-skills.tar.gz"
        _sums_url="$BATHO_BASE_URL/latest/download/sha256sums.txt"
    else
        _nover=${_ver#v}
        _tgz_url="$BATHO_BASE_URL/download/$_ver/batho-skills-$_nover.tar.gz"
        _sums_url="$BATHO_BASE_URL/download/$_ver/sha256sums.txt"
    fi
    warn "fetching $_tgz_url"
    download_to "$_tgz_url" "$_dest/pack.tar.gz" || err "download failed: $_tgz_url"

    _expected="$EMBEDDED_SHA256"
    if [ -z "$_expected" ]; then
        download_to "$_sums_url" "$_dest/sha256sums.txt" || err "checksum file unavailable: $_sums_url"
        _expected=$(awk '{print $1}' "$_dest/sha256sums.txt" | head -n1)
    fi
    _actual=$(sha256_of "$_dest/pack.tar.gz")
    [ "$_actual" = "$_expected" ] || err "checksum mismatch for pack tarball (expected $_expected, got $_actual) — aborting"
    warn "sha256 verified ($_actual)"

    mkdir -p "$_dest/extract"
    tar -xzf "$_dest/pack.tar.gz" -C "$_dest/extract" || err "tar extract failed"
    # locate the skills dir inside the archive (top-level dir may vary)
    _skills=""
    for _d in "$_dest/extract"/*/skills "$_dest/extract/skills"; do
        [ -d "$_d" ] && _skills=$_d && break
    done
    [ -n "$_skills" ] || err "archive did not contain a skills/ directory"
    printf '%s' "$_skills"
}

# ---- main ----------------------------------------------------------------

usage() {
    cat <<'EOF'
batho skill pack installer

  curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh | sh

options (flags via `sh -s -- ...` or env vars):
  --global | --project   install scope (default: global -> ~/.agents/skills)
  --agent <name>         force a specific agent (repeatable)
  --all                  write every known agent's dirs (skip detection)
  --remove               uninstall pack skills
  --list                 show what would be written, then exit
  --copy                 copy instead of symlink for mirrors
  --mcp                  also merge the batho MCP server into detected clients
  -y, --yes              non-interactive (also: NONINTERACTIVE=1 / CI=1)
  -h, --help             this help

env: BATHO_VERSION  BATHO_INSTALL_DIR  BATHO_AGENTS  BATHO_COPY=1
     BATHO_SCOPE=global|project  BATHO_BASE_URL (mirror/GHE override)
EOF
}

main() {
    _scope="${BATHO_SCOPE:-global}"
    _agents="${BATHO_AGENTS:-}"
    _all=0; _remove=0; _list=0; _copy="${BATHO_COPY:-0}"; _mcp=0; _yes="${NONINTERACTIVE:-${CI:-0}}"

    while [ $# -gt 0 ]; do
        case $1 in
            --global)  _scope=global ;;
            --project) _scope=project ;;
            --agent)   shift; _agents="${_agents:+$_agents }$1" ;;
            --all)     _all=1 ;;
            --remove)  _remove=1 ;;
            --list)    _list=1 ;;
            --copy)    _copy=1 ;;
            --mcp)     _mcp=1 ;;
            -y|--yes)  _yes=1 ;;
            -h|--help) usage; exit 0 ;;
            *) err "unknown option: $1 (try --help)" ;;
        esac
        shift
    done

    need_cmd uname; need_cmd tar; need_cmd mktemp
    case $(uname -s) in
        Darwin|Linux|FreeBSD|NetBSD|OpenBSD|MINGW*|MSYS*|CYGWIN*) ;;
        *) err "unsupported platform: $(uname -s) (use install.ps1 on native Windows)" ;;
    esac

    _proot=$(pwd)
    if [ "$_scope" = "global" ]; then
        # shellcheck disable=SC2088  # literal tilde consumed by expand_path
        _canonical="$(expand_path '~/.agents/skills')"
    else
        _canonical="$_proot/.agents/skills"
    fi

    # ---- list / remove short-circuit paths -------------------------------
    _targets=""
    if [ -n "${BATHO_INSTALL_DIR:-}" ]; then
        _targets="custom|$(expand_path "$BATHO_INSTALL_DIR")"
    else
        _targets="canonical|$_canonical"
        for _id in $(agent_ids); do
            _forced=0; _sel=0
            if [ "$_all" = "1" ]; then _sel=1; fi
            case " $_agents " in *" $_id "*) _sel=1; _forced=1 ;; esac
            if [ "$_sel" = "0" ] && ! agent_detected "$_id" "$_proot"; then continue; fi
            _ra=$(agent_field "$_id" 2)
            if [ "$_ra" = "0" ] || [ "$_forced" = "1" ] || [ "$_all" = "1" ]; then
                if [ "$_scope" = "global" ]; then _nd=$(agent_field "$_id" 7); else _nd=$(agent_field "$_id" 6); fi
                for _d in $(split_csv "$_nd"); do
                    _d=$(expand_path "$_d")
                    [ "$_scope" = "project" ] && _d="$_proot/$_d"
                    _targets="$_targets
${_id}|${_d}"
                done
            fi
        done
    fi

    if [ "$_list" = "1" ]; then
        say "batho-install: targets ($(printf '%s' "$_targets" | grep -c '|') scope roots):"
        printf '%s\n' "$_targets" | while IFS='|' read -r _a _d; do
            [ -n "$_a" ] && for _s in $PACK_SKILLS; do printf '  %-14s %s/%s\n' "$_a" "$_d" "$_s"; done
        done
        exit 0
    fi

    if [ "$_remove" = "1" ]; then
        printf '%s\n' "$_targets" | while IFS='|' read -r _a _d; do
            [ -n "$_a" ] || continue
            for _s in $PACK_SKILLS; do
                printf '%-18s %s:%s/%s\n' "$(remove_one "$_d/$_s")" "$_a" "$_d" "$_s"
            done
        done
        rm -f "$RECEIPT"
        say "batho-install: remove complete"
        exit 0
    fi

    # ---- fetch + verify + extract -----------------------------------------
    _tmp=$(mktemp -d 2>/dev/null || mktemp -d -t batho)
    trap 'rm -rf "$_tmp"' EXIT INT TERM

    _src_skills=$(fetch_pack "$_tmp" | tail -n1)
    [ -d "$_src_skills" ] || err "extract failed"

    # Pass 1: canonical target gets REAL files (safe after temp cleanup).
    # Pass 2: mirrors symlink to the canonical copy (or copy with --copy).
    printf '%s\n' "$_targets" | while IFS='|' read -r _a _d; do
        [ -n "$_a" ] || continue
        mkdir -p "$_d"
        for _s in $PACK_SKILLS; do
            if [ ! -d "$_src_skills/$_s" ]; then warn "missing skill in archive: $_s"; continue; fi
            if [ "$_a" = "canonical" ] || [ "$_a" = "custom" ]; then
                _st=$(install_one "$_src_skills/$_s" "$_d/$_s" 1)
            else
                _st=$(install_one "$_canonical/$_s" "$_d/$_s" "$_copy")
            fi
            if [ -d "$_d/$_s" ] && [ ! -L "$_d/$_s" ]; then : > "$_d/$_s/.batho-skill" 2>/dev/null || true; fi
            printf '%-10s %s:%s/%s\n' "$_st" "$_a" "$_d" "$_s"
        done
    done

    # subshell-safe dir collection for the receipt
    WRITTEN_DIRS=$(printf '%s\n' "$_targets" | cut -d'|' -f2 | sort -u | tr '\n' ' ')
    write_receipt "$(resolve_version)" "$_scope"
    say "batho-install: receipt written to $RECEIPT"

    if [ "$_mcp" = "1" ]; then
        configure_mcp
    fi
    say "batho-install: done — restart your agent(s) to pick up the skills"
}

# ---- optional MCP registration (--mcp) -----------------------------------
# name|config path (~ expanded). Merged only: never overwrite other servers.
MCP_TARGETS='claude-desktop|~/Library/Application Support/Claude/claude_desktop_config.json
cursor|~/.cursor/mcp.json
windsurf|~/.codeium/windsurf/mcp_config.json
antigravity|~/.gemini/antigravity/mcp_config.json'

configure_mcp() {
    _bin=$(command -v batho 2>/dev/null || printf 'batho')
    printf '%s\n' "$MCP_TARGETS" | while IFS='|' read -r _name _cfg; do
        [ -n "$_name" ] || continue
        _cfg=$(expand_path "$_cfg")
        _dir=$(dirname "$_cfg")
        [ -d "$_dir" ] || { printf '%-14s %s\n' "skip(absent)" "$_name"; continue; }
        if [ ! -f "$_cfg" ]; then
            printf '{"mcpServers":{"batho":{"command":"%s","args":["mcp"]}}}\n' "$_bin" > "$_cfg"
            printf '%-14s %s\n' "wrote" "$_name"
            continue
        fi
        if command -v python3 >/dev/null 2>&1; then
            if BATHO_BIN="$_bin" BATHO_CFG="$_cfg" python3 - <<'PYEOF'
import json, os
cfg_path = os.environ["BATHO_CFG"]
with open(cfg_path) as fh:
    cfg = json.load(fh)
servers = cfg.setdefault("mcpServers", {})
if "batho" not in servers:
    servers["batho"] = {"command": os.environ["BATHO_BIN"], "args": ["mcp"]}
with open(cfg_path, "w") as fh:
    json.dump(cfg, fh, indent=2)
PYEOF
            then
                printf '%-14s %s\n' "merged" "$_name"
            else
                warn "merge failed: $_name"
            fi
        else
            printf '%-14s %s\n' "manual" "$_name"
            warn "add to $_cfg: {\"mcpServers\":{\"batho\":{\"command\":\"$_bin\",\"args\":[\"mcp\"]}}}"
        fi
    done
}

main "$@"
