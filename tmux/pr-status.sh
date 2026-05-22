#!/usr/bin/env bash
# Print PR status for the worktree at $1. Cache results to keep tmux snappy.
# Empty output if not a git repo, no PR, or gh unavailable.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

wt=$1
[ -z "$wt" ] && exit 0
[ ! -d "$wt" ] && exit 0

cache_dir="$HOME/.cache/tmux-pr"
mkdir -p "$cache_dir"
key=$(printf '%s' "$wt" | shasum | cut -c1-12)
cache="$cache_dir/$key"
lock="$cache_dir/$key.lock"
ttl=60

now=$(date +%s)
mtime=0
[ -f "$cache" ] && mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
age=$(( now - mtime ))

# Clean up stale lock from a crashed refresh (>120s old).
if [ -d "$lock" ]; then
    lock_mtime=$(stat -f %m "$lock" 2>/dev/null || echo 0)
    if [ $(( now - lock_mtime )) -gt 120 ]; then
        rmdir "$lock" 2>/dev/null
    fi
fi

refresh() {
    # Single in-flight refresh per worktree (mkdir is atomic; macOS has no flock)
    ( mkdir "$lock" 2>/dev/null || exit 0
      trap 'rmdir "$lock" 2>/dev/null' EXIT
      cd "$wt" 2>/dev/null || { : > "$cache"; exit 0; }
      git rev-parse --git-dir >/dev/null 2>&1 || { : > "$cache"; exit 0; }
      json=$(gh pr view --json number,state,isDraft,reviewDecision,statusCheckRollup 2>/dev/null) || { : > "$cache"; exit 0; }
      if [ -z "$json" ]; then
          : > "$cache"
          exit 0
      fi
      printf '%s' "$json" | jq -r '
        "#" + (.number|tostring) +
        (if .state == "MERGED" then " merged"
         elif .state == "CLOSED" then " closed"
         elif .isDraft then " draft"
         else
           ((.statusCheckRollup // []) as $r |
            if ($r | length) == 0 then ""
            elif ($r | any(.conclusion == "FAILURE" or .conclusion == "CANCELLED" or .conclusion == "TIMED_OUT")) then " ✕"
            elif ($r | any(.status == "IN_PROGRESS" or .status == "QUEUED" or .status == "PENDING")) then " ⏳"
            elif ($r | all(.conclusion == "SUCCESS" or .conclusion == "SKIPPED" or .conclusion == "NEUTRAL")) then " ✓"
            else "" end)
         end)
      ' 2>/dev/null | sed 's/ *$//' > "$cache"
    ) &
}

if [ ! -f "$cache" ]; then
    refresh
    exit 0
fi

if [ "$age" -ge "$ttl" ]; then
    refresh
fi

cat "$cache" 2>/dev/null
