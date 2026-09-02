#!/bin/bash
# Focus a Finder window in the current workspace if there is one; otherwise open
# a new Finder window here. Never jumps to a Finder window on another workspace.
export PATH="/opt/homebrew/bin:$PATH"
WS=$(aerospace list-workspaces --focused)
ID=$(aerospace list-windows --workspace "$WS" --format '%{window-id}|%{app-name}' | awk -F'|' '$2=="Finder"{print $1; exit}')
if [ -n "$ID" ]; then
  aerospace focus --window-id "$ID"
else
  # 'make new Finder window' (no target) always creates a window, even when the
  # "open folders in tabs" preference is on; set the folder afterwards.
  osascript -e 'tell application "Finder"
    set w to make new Finder window
    set target of w to (path to home folder)
    activate
  end tell'
fi
