#!/bin/sh
# Batho CLI installer — installs uv (if needed) then `uv tool install batho`.
#
#   curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install-batho.sh | sh
#
# Options:
#   --version <ver>   install a specific batho version (or BATHO_VERSION)
#   --yes / -y        non-interactive (also NONINTERACTIVE=1 / CI=1)
#   --help            usage
#
# Env: UV_INSTALL_DIR, UV_NO_MODIFY_PATH (passed through to the uv installer),
# BATHO_VERSION, UV_URL (uv installer mirror override).
#
# Everything below is functions; `main` runs last so a truncated download
# executes nothing.

set -eu

say()  { printf '%s\n' "$*"; }
warn() { printf 'batho-install: %s\n' "$*" >&2; }
err()  { warn "$*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

UV_URL="${UV_URL:-https://astral.sh/uv/install.sh}"
BATHO_VERSION="${BATHO_VERSION:-}"

usage() {
    sed -n '2,14p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//' || cat <<'EOF'
batho CLI installer — installs uv if needed, then `uv tool install batho`.
  curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install-batho.sh | sh
flags: --version <ver>  --yes  --help   env: BATHO_VERSION, UV_INSTALL_DIR
EOF
}

check_platform() {
    have uname || err "uname not found"
    case $(uname -s) in
        Darwin|Linux|FreeBSD|NetBSD|OpenBSD|MINGW*|MSYS*|CYGWIN*) ;;
        *) err "unsupported platform: $(uname -s) — on Windows use: powershell -c \"irm https://astral.sh/uv/install.ps1 | iex; uv tool install batho\"" ;;
    esac
    have curl || have wget || have fetch || err "need curl, wget, or fetch"
}

ensure_uv() {
    if have uv; then
        say "uv $(uv --version 2>/dev/null | awk '{print $2}') found"
        return 0
    fi
    warn "uv not found — installing via $UV_URL"
    if have curl; then
        curl --proto '=https' --tlsv1.2 -fsSL "$UV_URL" | sh
    elif have wget; then
        wget --https-only -qO- "$UV_URL" | sh
    else
        fetch -qo- "$UV_URL" | sh
    fi
    # uv installs to ~/.local/bin (or UV_INSTALL_DIR) — may not be on PATH yet
    if ! have uv; then
        for _d in "${UV_INSTALL_DIR:-}" "$HOME/.local/bin" "$HOME/.cargo/bin"; do
            [ -x "$_d/uv" ] && PATH="$_d:$PATH" && break
        done
    fi
    export PATH
    have uv || err "uv installed but not on PATH — restart your shell and run: uv tool install batho"
}

install_batho() {
    if [ -n "$BATHO_VERSION" ]; then
        _spec="batho==$BATHO_VERSION"
    else
        _spec="batho"
    fi
    if have batho; then
        warn "batho already installed ($(batho --version 2>/dev/null || echo '?')) — upgrading"
        uv tool upgrade batho || uv tool install --force "$_spec"
    else
        uv tool install "$_spec"
    fi
    have batho || err "batho installed but not on PATH — run: uv tool update-shell, then restart your shell"
    say "batho-install: installed $(batho --version 2>/dev/null || echo 'batho')"
}

main() {
    while [ $# -gt 0 ]; do
        case $1 in
            --version) shift; BATHO_VERSION=$1 ;;
            -y|--yes) : ;;
            -h|--help) usage; exit 0 ;;
            *) err "unknown option: $1 (try --help)" ;;
        esac
        shift
    done
    check_platform
    ensure_uv
    install_batho
    cat <<'EOF'

batho is ready. Next:
  batho mcp          # stdio MCP server (register in your agent's config)
  batho build        # build a code-graph artifact for a repo

Skill pack:  curl -fsSL https://github.com/sageoz/batho-skills/releases/latest/download/install.sh | sh
             or: npx skills add sageoz/batho-skills
EOF
}

main "$@"
