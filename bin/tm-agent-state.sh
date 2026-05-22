#!/bin/zsh
set -eu

state="${1:-}"
agent="${2:-agent}"

if [[ -z "$state" || -z "${TMUX:-}" || -z "${TMUX_PANE:-}" ]]; then
  exit 0
fi

session="$(tmux display-message -p -t "$TMUX_PANE" '#S' 2>/dev/null || true)"
if [[ -z "$session" ]]; then
  exit 0
fi

case "$state" in
  done)
    tmux set-option -q -t "$session" @agent_state "DONE"
    tmux set-option -q -t "$session" @agent_state_agent "$agent"
    tmux set-option -q -t "$session" @agent_state_time "$(date +%H:%M)"
    ;;
  clear)
    tmux set-option -q -u -t "$session" @agent_state || true
    tmux set-option -q -u -t "$session" @agent_state_agent || true
    tmux set-option -q -u -t "$session" @agent_state_time || true
    ;;
esac
