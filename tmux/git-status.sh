#!/usr/bin/env bash
# Print unpushed/dirty indicators for the worktree at $1.
# ↑N = N commits ahead of upstream, ↓N = behind, ● = uncommitted changes.

wt=$1
[ -z "$wt" ] && exit 0
[ ! -d "$wt" ] && exit 0
cd "$wt" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

ab=""
upstream=$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null)
if [ -n "$upstream" ]; then
    counts=$(git rev-list --left-right --count "@{u}...HEAD" 2>/dev/null)
    behind=$(printf '%s' "$counts" | awk '{print $1}')
    ahead=$(printf '%s' "$counts" | awk '{print $2}')
    [ "${ahead:-0}" -gt 0 ] && ab="${ab}↑${ahead}"
    [ "${behind:-0}" -gt 0 ] && ab="${ab}↓${behind}"
fi

dirty=""
[ -n "$(git status --porcelain 2>/dev/null)" ] && dirty="●"

if [ -n "$ab" ] && [ -n "$dirty" ]; then
    printf '%s %s' "$ab" "$dirty"
elif [ -n "$ab" ]; then
    printf '%s' "$ab"
elif [ -n "$dirty" ]; then
    printf '%s' "$dirty"
fi
