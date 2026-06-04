#!/usr/bin/env bash
# Refresh per-session status options for every session, sampling in parallel so
# the wall-clock cost is one sample window regardless of session count.
#   @agent_running - whether an agent is actively working (agent-running.sh)
#   @pr_status     - PR number/state for the session's @worktree (pr-status.sh)
#   @git_status    - ahead/behind/dirty indicators for @worktree (git-status.sh)
# These are precomputed into options because tmux cannot expand per-row format
# vars (like #{@worktree}) inside an inline #() in status-right / choose-tree.

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/tmuxagents.XXXXXX") || exit 0
trap 'rm -rf "$tmpdir"' EXIT

sessions=()
while IFS= read -r s; do
    [ -z "$s" ] && continue
    sessions+=("$s")
    key=$(printf '%s' "$s" | tr / _)
    (
        wt=$(tmux show-option -qv -t "$s" @worktree 2>/dev/null)
        SAMPLE_MS="${SAMPLE_MS:-200}" ~/.tmux/agent-running.sh "$s" > "$tmpdir/$key.agent" 2>/dev/null
        if [ -n "$wt" ]; then
            ~/.tmux/pr-status.sh "$wt" > "$tmpdir/$key.pr" 2>/dev/null
            ~/.tmux/git-status.sh "$wt" > "$tmpdir/$key.git" 2>/dev/null
        fi
    ) &
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

wait

for s in "${sessions[@]}"; do
    key=$(printf '%s' "$s" | tr / _)
    for opt in agent_running:agent pr_status:pr git_status:git; do
        name=${opt%%:*}
        val=$(cat "$tmpdir/$key.${opt#*:}" 2>/dev/null)
        if [ -n "$val" ]; then
            tmux set-option -q -t "$s" "@$name" "$val"
        else
            tmux set-option -q -u -t "$s" "@$name" 2>/dev/null
        fi
    done
done
