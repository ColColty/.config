# Tomàs' .config

This is the configuration of my system. It is a work in progress and it is constantly changing.

## Quick Start

### Installation on a New Computer

1. **Clone this repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Run the install script:**
   ```bash
   ./install.sh
   ```

   This will:
   - Create symlinks from `~/.config/` to the configs in this repo
   - Set up `~/bin/` scripts
   - Back up any existing configs to `~/.config-backup-YYYYMMDD-HHMMSS/`

3. **Add `~/bin` to your PATH** (add to your `.zshrc` or `.bashrc`):
   ```bash
   export PATH="$HOME/bin:$PATH"
   ```

### Keeping Your Config Updated

Since everything is symlinked, just pull the latest changes:

```bash
cd ~/.dotfiles
git pull
```

Changes apply immediately - no need to re-run the install script!

### Uninstalling

To remove the symlinks (keeps your dotfiles repo intact):

```bash
./uninstall.sh
```

## What Gets Installed

| Config | Location | Description |
|--------|----------|-------------|
| `aerospace/` | `~/.config/aerospace/` | Aerospace window manager |
| `alacritty/` | `~/.config/alacritty/` | Alacritty terminal |
| `karabiner/` | `~/.config/karabiner/` | Karabiner key remapping |
| `nvim/` | `~/.config/nvim/` | Neovim configuration |
| `sketchybar/` | `~/.config/sketchybar/` | Sketchybar status bar |
| `tmux/` | `~/.config/tmux/` + `~/.tmux.conf` | Tmux configuration |
| `bin/` | `~/bin/` | Custom shell scripts |

## macOS-Specific Setup

### Custom Keyboard Layout

Install the custom keyboard layout:

```bash
sudo cp -r keyboard/Code.bundle /Library/Keyboard\ Layouts/
```

Then go to **System Preferences > Keyboard > Input Sources** and add the new layout.

### Sketchybar Helper

Build the sketchybar helper (required for CPU monitoring):

```bash
cd sketchybar/helper
make
```

## Prerequisites

### Development Tools

- [ ] Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- [ ] Install nvim: `brew install neovim`
- [ ] Install zsh: `brew install zsh`
- [ ] Install tmux: `brew install tmux`
- [ ] Install fzf: `brew install fzf`
- [ ] Install ripgrep: `brew install ripgrep`
- [ ] Install fd: `brew install fd`
- [ ] Install Docker Desktop

### macOS Apps

- [ ] Install [Warp](https://www.warp.dev/) or [Alacritty](https://alacritty.org/)
- [ ] Install [Raycast](https://www.raycast.com/)
- [ ] Install [Karabiner-Elements](https://karabiner-elements.pqrs.org/)
- [ ] Install [Aerospace](https://github.com/nikitabobko/AeroSpace)
- [ ] Install [Sketchybar](https://github.com/FelixKratz/SketchyBar): `brew tap FelixKratz/formulae && brew install sketchybar`
- [ ] Install [Homerow](https://www.homerow.app/)
- [ ] Install [Ukelele](https://software.sil.org/ukelele/) (for keyboard layout editing)

### Productivity Apps

- [ ] Install [Notion](https://www.notion.so/)
- [ ] Install Notion Calendar
- [ ] Install DataGrip
- [ ] Install Postman

### Optional Apps

- [ ] Install [Hidden Bar](https://github.com/dwarvesf/hidden)
- [ ] Install [KeyCastr](https://github.com/keycastr/keycastr)
- [ ] Install Hand Mirror

## Custom Scripts

### `tm-layout.sh`
Sets up the default tmux window layout (nvim, zsh, opencode windows). Automatically runs when creating a new tmux session.

### `tm-worktree.sh`
Git worktree management script. Use with `prefix + Shift+W` in tmux to:
- Create a new git worktree and tmux session
- Remove existing worktrees

## Making Changes

1. Edit configs directly in this repo (they're symlinked!)
2. Commit and push your changes:
   ```bash
   cd ~/.dotfiles
   git add .
   git commit -m "Update config"
   git push
   ```

3. On other machines, just `git pull` to sync
