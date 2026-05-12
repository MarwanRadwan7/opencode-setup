#!/usr/bin/env bash
# =============================================================================
# setup-lsps.sh — Install LSP servers for opencode
# https://github.com/marwanradwan7/opencode-setup
#
# Usage:
#   bash setup-lsps.sh
#
# On Windows, run from Git Bash or WSL.
# Servers that opencode auto-downloads are not included here.
# Language runtimes (Go, Rust, Node, Java, etc.) must already be installed.
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}==>${RESET} ${BOLD}$*${RESET}"; }
success() { echo -e "${GREEN} ✓${RESET}  $*"; }
warn()    { echo -e "${YELLOW} ⚠${RESET}  Skipping $*"; }
error()   { echo -e "${RED} ✗${RESET}  $*"; }
divider() { echo -e "\n${BOLD}────────────────────────────────────────${RESET}"; }

# ── Helpers ───────────────────────────────────────────────────────────────────
has() { command -v "$1" &>/dev/null; }

need() {
  local cmd=$1 label=$2
  if ! has "$cmd"; then
    warn "$label ('$cmd' not found — install the runtime first)"
    return 1
  fi
  return 0
}

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

ensure_path() {
  if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    echo -e "\n${YELLOW}Note:${RESET} Add ~/.local/bin to your PATH:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
}

download() {
  local url=$1 dest=$2
  if has curl; then
    curl -fsSL "$url" -o "$dest"
  elif has wget; then
    wget -qO "$dest" "$url"
  else
    error "Neither curl nor wget found. Please install one."
    exit 1
  fi
}

github_latest() {
  local repo=$1
  if has curl; then
    curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
      | grep '"tag_name"' | cut -d'"' -f4
  elif has wget; then
    wget -qO- "https://api.github.com/repos/$repo/releases/latest" \
      | grep '"tag_name"' | cut -d'"' -f4
  fi
}

# ── OS / Arch detection ───────────────────────────────────────────────────────
OS="linux"
ARCH="x86_64"

case "$(uname -s)" in
  Darwin)  OS="macos" ;;
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
  Linux)   OS="linux" ;;
esac

case "$(uname -m)" in
  arm64|aarch64) ARCH="aarch64" ;;
  x86_64|amd64)  ARCH="x86_64" ;;
esac

divider
info "opencode LSP installer"
echo "  OS:   $OS"
echo "  Arch: $ARCH"
divider

# =============================================================================
# Node.js LSPs  (cross-platform)
# =============================================================================
info "Node.js-based LSPs"

if need node "Node LSPs"; then
  npm install -g \
    typescript \
    typescript-language-server \
    pyright \
    vscode-langservers-extracted \
    @prisma/language-server \
    bash-language-server \
    2>/dev/null && success "Node LSPs installed" || error "Some Node LSPs failed — check npm output"
fi

# =============================================================================
# Python — pyright (via Node, above) + pylsp (via pip)
# =============================================================================
divider; info "Python — pylsp"
 
if need python3 "pylsp"; then
  PIP_CMD=""
  if has pip3; then
    PIP_CMD="pip3"
  elif has pip; then
    PIP_CMD="pip"
  elif python3 -m pip --version &>/dev/null 2>&1; then
    PIP_CMD="python3 -m pip"
  fi
 
  if [[ -n "$PIP_CMD" ]]; then
    $PIP_CMD install --user --quiet "python-lsp-server[all]" \
      && success "pylsp (python-lsp-server[all])"
  else
    warn "pylsp (pip not found — install pip first)"
  fi
 
  has pyright \
    && success "pyright (installed via Node above)" \
    || warn "pyright (run the Node LSPs section first)"
fi


# =============================================================================
# Go — gopls
# =============================================================================
divider; info "Go — gopls"

if need go "gopls"; then
  go install golang.org/x/tools/gopls@latest && success "gopls"
fi

# =============================================================================
# .NET — csharp-ls  (C# / F# / Razor)
# =============================================================================
divider; info ".NET — csharp-ls"

if need dotnet "csharp-ls"; then
  dotnet tool install --global csharp-ls 2>/dev/null \
    || dotnet tool update --global csharp-ls
  success "csharp-ls"
fi

# =============================================================================
# Nix — nixd  (Linux / macOS only)
# =============================================================================
divider; info "Nix — nixd"

if [[ "$OS" == "windows" ]]; then
  warn "nixd (not supported on Windows — use WSL)"
elif need nix "nixd"; then
  nix profile install nixpkgs#nixd && success "nixd"
fi

# =============================================================================
# Java — jdtls  (Linux / macOS)
# =============================================================================
divider; info "Java — jdtls"

if [[ "$OS" == "windows" ]]; then
  echo "  → On Windows, install jdtls via Scoop: scoop install jdtls"
elif need java "jdtls"; then
  JDTLS_DIR="$HOME/.local/share/jdtls"
  mkdir -p "$JDTLS_DIR"

  JDTLS_META=$(curl -fsSL "https://download.eclipse.org/jdtls/milestones/?format=json" 2>/dev/null \
    | grep -o '"[0-9]*\.[0-9]*\.[0-9]*"' | head -1 | tr -d '"') || JDTLS_META="1.38.0"

  download \
    "https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/${JDTLS_META}/jdt-language-server-${JDTLS_META}.tar.gz&r=1" \
    /tmp/jdtls.tar.gz

  tar -xzf /tmp/jdtls.tar.gz -C "$JDTLS_DIR"
  success "jdtls → $JDTLS_DIR"
fi

# =============================================================================
# Done
# =============================================================================
divider
echo -e "\n${GREEN}${BOLD}All done!${RESET}\n"
echo "Servers skipped above were either:"
echo "  • already bundled with their runtime (dart, gleam)"
echo "  • auto-downloaded by opencode (astro, bash, clangd, kotlin,"
echo "    lua, php, svelte, terraform, tinymist, vue, yaml)"
echo "  • missing a required runtime — install the runtime and re-run"
echo ""
ensure_path
echo ""
