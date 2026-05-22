#!/usr/bin/env bash
# bootstrap.sh — set up a new machine from this dotfiles repo
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# ── Colours ──────────────────────────────────────────────────────────────────
BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
step()    { printf "\n${BOLD}▸ %s${RESET}\n" "$*"; }
ok()      { printf "  ${GREEN}✓${RESET} %s\n" "$*"; }
linking() { printf "  ${CYAN}→${RESET} %s\n" "$*"; }

# ── Helpers ───────────────────────────────────────────────────────────────────
symlink() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mv "$dst" "$dst.bak"
        linking "Backed up existing $dst → $dst.bak"
    fi
    ln -sfn "$src" "$dst"
    ok "$dst → $src"
}

# ── 1. Homebrew ───────────────────────────────────────────────────────────────
step "Homebrew"
if ! command -v brew &>/dev/null; then
    linking "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for the rest of this script (Apple Silicon path)
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
else
    ok "Already installed: $(brew --version | head -1)"
fi

# ── 2. CLI tools ──────────────────────────────────────────────────────────────
step "CLI tools"
PACKAGES=(tmux gh jq fzf ripgrep fd)
for pkg in "${PACKAGES[@]}"; do
    if brew list --formula "$pkg" &>/dev/null; then
        ok "Already installed: $pkg"
    else
        linking "Installing $pkg…"
        brew install "$pkg"
        ok "$pkg"
    fi
done

# ── 3. Directories ────────────────────────────────────────────────────────────
step "Directories"
mkdir -p "$HOME/.tmux/plugins" "$HOME/.cache/tmux-pr" "$HOME/bin"
ok "~/.tmux/plugins, ~/.cache/tmux-pr, ~/bin"

# ── 4. TPM (tmux plugin manager) ─────────────────────────────────────────────
step "TPM"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    ok "Installed TPM"
else
    ok "TPM already present"
fi

# ── 5. Tmux config ────────────────────────────────────────────────────────────
step "Tmux config"
symlink "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
for f in "$DOTFILES/tmux/"*.sh; do
    chmod +x "$f"
    symlink "$f" "$HOME/.tmux/$(basename "$f")"
done

# ── 6. Bin scripts ────────────────────────────────────────────────────────────
step "Bin scripts"
for f in "$DOTFILES/bin/"*.sh; do
    chmod +x "$f"
    symlink "$f" "$HOME/bin/$(basename "$f")"
done

# ── 7. gh auth ────────────────────────────────────────────────────────────────
step "GitHub CLI auth"
if gh auth status &>/dev/null; then
    ok "Already authenticated: $(gh auth status 2>&1 | grep 'Logged in' | head -1 | xargs)"
else
    linking "Run: gh auth login"
    echo "  (skipping — run 'gh auth login' manually to enable PR status in tmux)"
fi

# ── 8. Reload tmux if running ─────────────────────────────────────────────────
step "Tmux"
if [ -n "${TMUX:-}" ]; then
    tmux source-file "$HOME/.tmux.conf" && ok "Config reloaded"
    echo "  Run 'prefix + I' inside tmux to install plugins (tmux-resurrect etc.)"
else
    ok "Not inside tmux — run 'tmux source-file ~/.tmux.conf' after starting tmux"
    echo "  Then run 'prefix + I' to install plugins"
fi

echo ""
printf "${GREEN}${BOLD}Bootstrap complete.${RESET}\n"
