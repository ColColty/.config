#!/usr/bin/env bash
# Heuristic: a pane running opencode/claude is "active" if its visible
# content changes during a short sample window (TUI is streaming). Else idle.
#
# Output: "opencode ▶" | "opencode ◌" | "claude ▶" | "claude ◌" | ""
# Env: SAMPLE_MS (default 200)

session=$1
[ -z "$session" ] && exit 0

SAMPLE_MS=${SAMPLE_MS:-200}

mapfile -t targets < <(
    tmux list-panes -s -t "$session" -F '#{pane_id} #{pane_current_command}' 2>/dev/null \
        | awk '$2 == "opencode" || $2 == "claude" { print $0 }'
)
[ ${#targets[@]} -eq 0 ] && exit 0

declare -A first
for line in "${targets[@]}"; do
    pid=${line%% *}
    first[$pid]=$(tmux capture-pane -p -t "$pid" 2>/dev/null)
done

# Single sleep covers all panes
sleep "$(awk "BEGIN{printf \"%.3f\", $SAMPLE_MS/1000}")"

found_oc=""
found_cc=""
for line in "${targets[@]}"; do
    pid=${line%% *}
    cmd=${line#* }
    second=$(tmux capture-pane -p -t "$pid" 2>/dev/null)
    if [ "${first[$pid]}" != "$second" ]; then
        case "$cmd" in
            opencode) found_oc="active" ;;
            claude)   found_cc="active" ;;
        esac
    else
        case "$cmd" in
            opencode) [ -z "$found_oc" ] && found_oc="idle" ;;
            claude)   [ -z "$found_cc" ] && found_cc="idle" ;;
        esac
    fi
done

if [ -n "$found_oc" ]; then
    [ "$found_oc" = "active" ] && echo "opencode ▶" || echo "opencode ◌"
elif [ -n "$found_cc" ]; then
    [ "$found_cc" = "active" ] && echo "claude ▶" || echo "claude ◌"
fi
