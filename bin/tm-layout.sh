#!/usr/bin/env bash

SESSION="$1"

# 1. Get the first window index dynamically
FIRST_WIN=$(tmux display-message -p -t "${SESSION}:" "#{window_index}")

# 2. Setup First Window (Editor)
# We use 'respawn-pane -k' (kill) to replace the shell with nvim immediately.
# This prevents any "worktree created" logs from cluttering the screen.
tmux rename-window -t "${SESSION}:${FIRST_WIN}" "nvim" || true
tmux respawn-pane -k -t "${SESSION}:${FIRST_WIN}" "nvim ." || true

# 3. Window 2: Shell
tmux new-window -t "${SESSION}:" -n "zsh" || true

# 4. Window 3: Server
# For the server, we use send-keys so you can see the command output
# and stop/restart it if needed.
tmux new-window -t "${SESSION}:" -n "opencode" || true
LAST_WIN=$(tmux display-message -p -t "${SESSION}:" "#{window_index}")

# Small sleep to ensure the shell is ready for the command
sleep 0.2
tmux send-keys -t "${SESSION}:${LAST_WIN}" "opencode" C-m || true

# 5. Focus Editor
tmux select-window -t "${SESSION}:${FIRST_WIN}" || true

exit 0
