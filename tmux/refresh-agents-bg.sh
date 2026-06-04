#!/usr/bin/env bash
# Fire-and-forget wrapper. Uses mkdir-based lock to dedupe concurrent fires.
lock="/tmp/tmux-refresh-agents.lock"
(
    mkdir "$lock" 2>/dev/null || exit 0
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    # Stale-lock recovery: if older than 30s, drop and re-take (handled below)
    ~/.tmux/refresh-agents.sh >/dev/null 2>&1
) </dev/null >/dev/null 2>&1 &

# Stale-lock cleanup outside the lock: if lock dir is >30s old, remove it.
if [ -d "$lock" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$lock" 2>/dev/null || stat -f %m "$lock" 2>/dev/null || echo 0) ))
    [ "$age" -gt 30 ] && rmdir "$lock" 2>/dev/null
fi
