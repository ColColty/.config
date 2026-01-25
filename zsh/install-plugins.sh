#!/bin/bash

# ============================================================================
#                  Oh My Zsh External Plugins Installer
# ============================================================================
# This script installs the external zsh plugins referenced in .zshrc
# Run this after installing Oh My Zsh
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Oh My Zsh External Plugins Installer${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if Oh My Zsh is installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${YELLOW}Oh My Zsh is not installed.${NC}"
    echo -e "Install it first with:"
    echo -e "  sh -c \"\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    exit 1
fi

echo -e "ZSH_CUSTOM directory: ${GREEN}$ZSH_CUSTOM${NC}"
echo ""

# Create plugins directory if it doesn't exist
mkdir -p "$ZSH_CUSTOM/plugins"

# Function to clone or update a plugin
install_plugin() {
    local repo="$1"
    local name="$2"
    local target="$ZSH_CUSTOM/plugins/$name"

    if [ -d "$target" ]; then
        echo -e "  ${GREEN}[OK]${NC} $name (already installed)"
        # Optionally update
        # git -C "$target" pull --quiet
    else
        echo -e "  ${YELLOW}[INSTALLING]${NC} $name..."
        git clone --depth=1 "$repo" "$target" 2>/dev/null
        echo -e "  ${GREEN}[DONE]${NC} $name"
    fi
}

echo -e "${BLUE}Installing external plugins...${NC}"
echo ""

# zsh-autosuggestions - Fish-like autosuggestions
install_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" "zsh-autosuggestions"

# zsh-syntax-highlighting - Fish-like syntax highlighting
install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "zsh-syntax-highlighting"

# zsh-completions - Additional completion definitions
install_plugin "https://github.com/zsh-users/zsh-completions.git" "zsh-completions"

# zsh-history-substring-search - Fish-like history search (optional)
install_plugin "https://github.com/zsh-users/zsh-history-substring-search.git" "zsh-history-substring-search"

# fast-syntax-highlighting - Alternative to zsh-syntax-highlighting (optional, not used by default)
# install_plugin "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "fast-syntax-highlighting"

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}Plugin installation complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}Recommended tools to install:${NC}"
echo ""
echo -e "  ${GREEN}fzf${NC} - Fuzzy finder"
echo -e "    macOS:  brew install fzf && \$(brew --prefix)/opt/fzf/install"
echo -e "    Ubuntu: sudo apt install fzf"
echo ""
echo -e "  ${GREEN}fd${NC} - Fast file finder (faster than find)"
echo -e "    macOS:  brew install fd"
echo -e "    Ubuntu: sudo apt install fd-find"
echo ""
echo -e "  ${GREEN}eza${NC} - Modern ls replacement"
echo -e "    macOS:  brew install eza"
echo -e "    Ubuntu: sudo apt install eza"
echo ""
echo -e "  ${GREEN}bat${NC} - Cat with syntax highlighting"
echo -e "    macOS:  brew install bat"
echo -e "    Ubuntu: sudo apt install bat"
echo ""
echo -e "  ${GREEN}ripgrep${NC} - Fast grep alternative"
echo -e "    macOS:  brew install ripgrep"
echo -e "    Ubuntu: sudo apt install ripgrep"
echo ""
echo -e "  ${GREEN}direnv${NC} - Project-specific environment variables"
echo -e "    macOS:  brew install direnv"
echo -e "    Ubuntu: sudo apt install direnv"
echo ""
echo -e "${GREEN}Restart your terminal or run 'source ~/.zshrc' to apply changes!${NC}"
