#!/bin/bash

# Dotfiles Uninstall Script
# This script removes the symlinks created by install.sh
# Run: ./uninstall.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located (the dotfiles repo)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}       Dotfiles Uninstall Script${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Directories that were symlinked
CONFIG_DIRS=(
    "aerospace"
    "alacritty"
    "direnv"
    "karabiner"
    "nvim"
    "sketchybar"
    "tmux"
)

# Scripts that were symlinked
BIN_SCRIPTS=(
    "tm-layout.sh"
    "tm-worktree.sh"
)

# Function to remove a symlink only if it points to our dotfiles
remove_symlink() {
    local target="$1"
    local name="$2"
    local expected_source="$3"

    if [ -L "$target" ]; then
        local current_source=$(readlink "$target")
        if [ "$current_source" = "$expected_source" ]; then
            rm "$target"
            echo -e "  ${GREEN}[REMOVED]${NC} $name"
        else
            echo -e "  ${YELLOW}[SKIP]${NC} $name (points elsewhere: $current_source)"
        fi
    elif [ -e "$target" ]; then
        echo -e "  ${YELLOW}[SKIP]${NC} $name (not a symlink)"
    else
        echo -e "  ${BLUE}[OK]${NC} $name (doesn't exist)"
    fi
}

echo -e "${BLUE}Removing config symlinks...${NC}"
echo ""

for dir in "${CONFIG_DIRS[@]}"; do
    source_path="$DOTFILES_DIR/$dir"
    target_path="$CONFIG_DIR/$dir"
    remove_symlink "$target_path" "$dir" "$source_path"
done

echo ""
echo -e "${BLUE}Removing bin script symlinks...${NC}"
echo ""

for script in "${BIN_SCRIPTS[@]}"; do
    source_path="$DOTFILES_DIR/bin/$script"
    target_path="$HOME/bin/$script"
    remove_symlink "$target_path" "$script" "$source_path"
done

echo ""
echo -e "${BLUE}Removing tmux config symlink...${NC}"
echo ""

remove_symlink "$HOME/.tmux.conf" ".tmux.conf" "$DOTFILES_DIR/tmux/.tmux.conf"

echo ""
echo -e "${BLUE}Removing zsh config symlink...${NC}"
echo ""

remove_symlink "$HOME/.zshrc" ".zshrc" "$DOTFILES_DIR/zsh/.zshrc"

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}Uninstall complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check for backup directories
BACKUPS=$(ls -d "$HOME/.config-backup-"* 2>/dev/null || true)
if [ -n "$BACKUPS" ]; then
    echo -e "${YELLOW}Note:${NC} You have backup directories from previous installations:"
    echo "$BACKUPS"
    echo ""
    echo "You can restore them manually if needed."
    echo ""
fi

echo -e "${GREEN}Dotfiles have been unlinked.${NC}"
echo "Your dotfiles repo remains at: $DOTFILES_DIR"
