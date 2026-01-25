#!/bin/bash

# Dotfiles Installation Script
# This script creates symlinks from your home directory to the dotfiles in this repo
# Run: ./install.sh

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
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}       Dotfiles Installation Script${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "Dotfiles location: ${GREEN}$DOTFILES_DIR${NC}"
echo -e "Config directory:  ${GREEN}$CONFIG_DIR${NC}"
echo ""

# Directories to symlink to ~/.config/
CONFIG_DIRS=(
    "aerospace"
    "alacritty"
    "karabiner"
    "nvim"
    "sketchybar"
    "tmux"
)

# Scripts to symlink to ~/bin/
BIN_SCRIPTS=(
    "tm-layout.sh"
    "tm-worktree.sh"
)

# Function to create a symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ]; then
        # It's already a symlink
        local current_source=$(readlink "$target")
        if [ "$current_source" = "$source" ]; then
            echo -e "  ${GREEN}[OK]${NC} $name (already linked)"
            return
        else
            echo -e "  ${YELLOW}[UPDATE]${NC} $name (updating symlink)"
            rm "$target"
        fi
    elif [ -e "$target" ]; then
        # It exists but isn't a symlink - back it up
        echo -e "  ${YELLOW}[BACKUP]${NC} $name -> $BACKUP_DIR/"
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/"
    fi

    ln -s "$source" "$target"
    echo -e "  ${GREEN}[LINKED]${NC} $name"
}

# Create ~/.config if it doesn't exist
mkdir -p "$CONFIG_DIR"

echo -e "${BLUE}Setting up config directories...${NC}"
echo ""

for dir in "${CONFIG_DIRS[@]}"; do
    source_path="$DOTFILES_DIR/$dir"
    target_path="$CONFIG_DIR/$dir"

    if [ -d "$source_path" ]; then
        create_symlink "$source_path" "$target_path" "$dir"
    else
        echo -e "  ${RED}[SKIP]${NC} $dir (not found in dotfiles)"
    fi
done

echo ""
echo -e "${BLUE}Setting up bin scripts...${NC}"
echo ""

# Create ~/bin if it doesn't exist
mkdir -p "$HOME/bin"

for script in "${BIN_SCRIPTS[@]}"; do
    source_path="$DOTFILES_DIR/bin/$script"
    target_path="$HOME/bin/$script"

    if [ -f "$source_path" ]; then
        create_symlink "$source_path" "$target_path" "$script"
        chmod +x "$source_path"
    else
        echo -e "  ${RED}[SKIP]${NC} $script (not found in dotfiles)"
    fi
done

echo ""
echo -e "${BLUE}Setting up tmux config...${NC}"
echo ""

# Tmux expects .tmux.conf in home directory OR in ~/.config/tmux/tmux.conf
# Create a symlink at ~/.tmux.conf pointing to the tmux config
if [ -f "$DOTFILES_DIR/tmux/.tmux.conf" ]; then
    create_symlink "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf" ".tmux.conf"
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if backup was created
if [ -d "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}Note:${NC} Existing configs were backed up to:"
    echo -e "      $BACKUP_DIR"
    echo ""
fi

# Remind about PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo -e "${YELLOW}Reminder:${NC} Add ~/bin to your PATH if not already done:"
    echo -e '  export PATH="$HOME/bin:$PATH"'
    echo ""
fi

# Remind about keyboard layout (macOS specific)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${YELLOW}macOS Setup:${NC}"
    echo "  To install the custom keyboard layout, run:"
    echo "    sudo cp -r \"$DOTFILES_DIR/keyboard/Code.bundle\" /Library/Keyboard\\ Layouts/"
    echo ""
    echo "  To build the sketchybar helper (if using sketchybar):"
    echo "    cd \"$DOTFILES_DIR/sketchybar/helper\" && make"
    echo ""
fi

echo -e "${GREEN}To update your dotfiles in the future:${NC}"
echo "  cd $DOTFILES_DIR && git pull"
echo ""
echo -e "${GREEN}Changes will automatically apply via symlinks!${NC}"
