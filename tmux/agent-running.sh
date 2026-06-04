#!/usr/bin/env bash
# Heuristic: a pane running opencode/claude is "running" if its visible content
# changes during a short sample window (TUI is streaming). Else idle.
#
# A session can hold several agents across windows. We sample every one and pick
# which to surface by score: running (+2) beats idle, and the agent in the
# active window (+1) wins ties. So a running agent shows even when idle agents of
# another kind sit in other windows; on a tie we prefer claude.
#
# Output: "opencode ▶" | "opencode ◌" | "claude ▶" | "claude ◌" | ""
# Env: SAMPLE_MS (default 200)

session=$1
[ -z "$session" ] && exit 0

SAMPLE_MS=${SAMPLE_MS:-200}

mapfile -t targets < <(
    tmux list-panes -s -t "$session" -F '#{pane_id} #{pane_current_command} #{window_active}' 2>/dev/null \
        | awk '$2 == "opencode" || $2 == "claude"'
)
[ ${#targets[@]} -eq 0 ] && exit 0

declare -A first
for line in "${targets[@]}"; do
    pid=${line%% *}
    first[$pid]=$(tmux capture-pane -p -t "$pid" 2>/dev/null)
done

# Single sleep covers all panes
sleep "$(awk "BEGIN{printf \"%.3f\", $SAMPLE_MS/1000}")"

# Per agent, keep the best-scoring pane and whether that pane is running.
declare -A score running
for line in "${targets[@]}"; do
    pid=${line%% *}
    rest=${line#* }
    cmd=${rest%% *}
    win_active=${rest##* }
    second=$(tmux capture-pane -p -t "$pid" 2>/dev/null)
    is_running=0
    [ "${first[$pid]}" != "$second" ] && is_running=1
    s=$(( is_running * 2 + win_active ))
    if [ -z "${score[$cmd]}" ] || [ "$s" -gt "${score[$cmd]}" ]; then
        score[$cmd]=$s
        running[$cmd]=$is_running
    fi
done

# Highest score wins; iterating claude first means ties go to claude.
best=""
for cmd in claude opencode; do
    [ -z "${score[$cmd]}" ] && continue
    if [ -z "$best" ] || [ "${score[$cmd]}" -gt "${score[$best]}" ]; then
        best=$cmd
    fi
done
[ -z "$best" ] && exit 0

[ "${running[$best]}" = "1" ] && echo "$best ▶" || echo "$best ◌"
