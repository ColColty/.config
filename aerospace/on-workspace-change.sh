#!/bin/bash
# Runs on every workspace change (exec-on-workspace-change).
export PATH="/opt/homebrew/bin:$PATH"

# 1. Update the bar
sketchybar --trigger aerospace_workspace_change \
  AEROSPACE_FOCUSED_WORKSPACE="$AEROSPACE_FOCUSED_WORKSPACE" \
  AEROSPACE_PREV_WORKSPACE="$AEROSPACE_PREV_WORKSPACE"

# 2. Workspaces 1 and 2 are always "windowed" (accordion). "S" is the hidden
#    scratchpad parking workspace: if macOS drags us there (Cmd-Tab onto a
#    hidden window), pull the scratchpad out over the workspace we came from.
case "$AEROSPACE_FOCUSED_WORKSPACE" in
  1|2) aerospace layout h_accordion 2>/dev/null ;;
  S)   exec "$HOME/.config/aerospace/scratchpad.sh" show "${AEROSPACE_PREV_WORKSPACE:-1}" ;;
esac

# 3. Picture-in-Picture windows are visible on every workspace anyway, so keep
#    them in the current one. Interacting with the PiP then never yanks you to
#    the workspace it was born in.
aerospace list-windows --all --format '%{window-id}|%{window-title}' 2>/dev/null \
  | grep -i 'picture-in-picture' \
  | while IFS='|' read -r id _; do
      aerospace move-node-to-workspace --window-id "$id" "$AEROSPACE_FOCUSED_WORKSPACE" 2>/dev/null
    done
