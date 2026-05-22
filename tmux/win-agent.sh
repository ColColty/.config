#!/usr/bin/env bash
# Print " ▶" / " ◌" suffix when a window contains opencode (or " ▶" for claude).
# Args: <session_name> <window_index>

session=$1
window_index=$2
[ -z "$session" ] || [ -z "$window_index" ] && exit 0

cmds=$(tmux list-panes -t "${session}:${window_index}" -F '#{pane_current_command}' 2>/dev/null) || exit 0

has_oc=$(printf '%s\n' "$cmds" | grep -cx opencode 2>/dev/null)
has_cc=$(printf '%s\n' "$cmds" | grep -cx claude 2>/dev/null)

if [ "${has_oc:-0}" -gt 0 ]; then
    worktree=$(tmux show-option -qv -t "$session" @worktree 2>/dev/null)
    DB="$HOME/.local/share/opencode/opencode.db"
    SQLITE="${SQLITE:-$(command -v sqlite3 2>/dev/null || echo /usr/bin/sqlite3)}"
    if [ -n "$worktree" ] && [ -x "$SQLITE" ] && [ -f "$DB" ]; then
        esc_wt=${worktree//\'/\'\'}
        last=$("$SQLITE" "$DB" "SELECT MAX(time_updated) FROM session WHERE directory='${esc_wt}';" 2>/dev/null)
        if [ -n "$last" ] && [ "$last" != "" ]; then
            now=$(python3 -c 'import time;print(int(time.time()*1000))' 2>/dev/null)
            if [ -n "$now" ]; then
                diff=$(( now - last ))
                if [ "$diff" -lt 5000 ]; then printf ' ▶'; else printf ' ◌'; fi
                exit 0
            fi
        fi
    fi
    printf ' ▶'
    exit 0
fi

[ "${has_cc:-0}" -gt 0 ] && printf ' ▶'
