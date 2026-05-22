#!/usr/bin/env bash
# Refresh @agent_running for every session, sampling in parallel so the
# wall-clock cost is one sample window regardless of session count.

tmpdir=$(mktemp -d -t tmuxagents) || exit 0
trap 'rm -rf "$tmpdir"' EXIT

sessions=()
while IFS= read -r s; do
    [ -z "$s" ] && continue
    sessions+=("$s")
    ( SAMPLE_MS="${SAMPLE_MS:-200}" ~/.tmux/agent-running.sh "$s" > "$tmpdir/$(printf '%s' "$s" | tr / _)" 2>/dev/null ) &
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

wait

for s in "${sessions[@]}"; do
    f="$tmpdir/$(printf '%s' "$s" | tr / _)"
    r=$(cat "$f" 2>/dev/null)
    if [ -n "$r" ]; then
        tmux set-option -q -t "$s" @agent_running "$r"
    else
        tmux set-option -q -u -t "$s" @agent_running 2>/dev/null
    fi
done
