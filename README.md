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
| `omniwm/` | `~/.config/omniwm/` | OmniWM window manager (current) + switch/port scripts |
| `aerospace/` | `~/.config/aerospace/` | AeroSpace window manager (previous, kept as fallback) |
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

## Window manager: OmniWM

[OmniWM](https://omniwm.app) replaced AeroSpace on 2026-09-05 for its Niri-style scrolling layout.
It needs macOS 26 (Tahoe) on Apple Silicon.

### Install

```bash
brew tap BarutSRB/tap
brew trust --cask barutsrb/tap/omniwm   # third-party tap; Homebrew asks for this once
brew install omniwm                     # installs OmniWM.app and the omniwmctl CLI
```

### First launch and permissions

1. Open OmniWM once. Grant **Accessibility** and **Input Monitoring** when macOS asks.
   Screen Recording is optional (only for Overview thumbnails) and can be skipped.
2. Some shortcuts run scripts through Karabiner (see below). For the float-resize
   scripts to work, also add **Karabiner-Console-User-Server** to
   System Settings > Privacy & Security > Accessibility. The first `alt+shift+f`
   pops the macOS prompt for it; otherwise add
   `/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Console-User-Server.app`
   with the `+` button.
3. OmniWM registers itself as a login item on first launch.

### Apply this config

```bash
~/.config/omniwm/switch.sh to-omniwm
```

This quits AeroSpace (and turns off its login item), starts OmniWM, runs
`port-from-aerospace.py` against OmniWM's generated `settings.toml` (gaps, 10
workspaces, AeroSpace-style hotkeys, app rules via `omniwmctl rule add`, IPC on,
OmniWM's own workspace bar off), switches Sketchybar to the `omniwm.sh` items,
adds the Karabiner rule with the shell-command shortcuts, and loads the
`follow-new-windows` launchd agent. `switch.sh back` reverts all of it.

Notes:
- `settings.toml` is live-reloaded. Never append raw `[[appRules]]` blocks by hand:
  OmniWM rejects the whole file and silently keeps the previous settings. Use
  `omniwmctl rule add ...`.
- Hotkey ids `switchWorkspace.N` are zero-based (`.0` = `alt+1`). Only workspaces
  1-9 can have hotkeys; workspace 10 goes through Karabiner -> `omniwmctl`.
- With the MacBook display active, run `python3 ~/.config/omniwm/port-from-aerospace.py`
  once to add its zero top gap (the bar lives in the notch band there).
- Sketchybar runs as a brew service: `brew services start sketchybar`.

### Shortcuts

| Keys | Action |
|------|--------|
| `alt+h/j/k/l` | focus (also works out of a floating window) |
| `alt+shift+h/j/k/l` | move window |
| `alt+1..9`, `alt+0` | workspace 1-10 |
| `alt+shift+1..9`, `alt+shift+0` | move window to workspace |
| `alt+[` / `alt+]` | previous / next workspace |
| `alt+tab` | workspace back-and-forth |
| `alt+shift+tab` | move workspace to the monitor on the right |
| `alt+f` | fullscreen (keeps the bar gap) |
| `alt+shift+f` | toggle float, 70% of the screen, centred |
| `alt+m` | centre the floating window |
| `alt+w` | toggle tabbed column (accordion) |
| `alt+e` | toggle workspace layout (Niri scrolling / dwindle) |
| `alt+b` | balance sizes |
| `alt+q` | close window |
| `alt+minus` / `alt+shift+minus` | toggle scratchpad 1 / send window to it |
| `alt+enter` | new Alacritty window |
| `` alt+` `` | Quake terminal |
| `ctrl+alt+space` | command palette |
| `alt+shift+o` | overview |

Files in `omniwm/`: `settings.toml`, `port-from-aerospace.py`, `switch.sh`,
`focus.sh`, `toggle-float.sh`, `center-float.sh`, `follow-new-windows.sh`,
`place_window.swift` (+ binary), `frontmost_pid.swift` (+ binary),
`karabiner-rule.json`, `launchd/`, `sketchybar/`.

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
- [ ] Install [OmniWM](https://github.com/BarutSRB/OmniWM): `brew tap BarutSRB/tap && brew install omniwm` (see [Window manager: OmniWM](#window-manager-omniwm))
- [ ] (fallback) Install [AeroSpace](https://github.com/nikitabobko/AeroSpace): `brew install --cask nikitabobko/tap/aerospace`
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
