#!/usr/bin/env bash
# Open the focused pane's pull request in the browser (falls back to the repo page).
# Bound to prefix+shift+g in ~/.config/herdr/config.toml.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
dir=$(herdr pane list 2>/dev/null | python3 -c '
import json,sys
for p in json.load(sys.stdin)["result"]["panes"]:
    if p.get("focused"):
        print(p.get("foreground_cwd") or p.get("cwd") or ""); break')
[ -n "$dir" ] && cd "$dir" || exit 0
gh pr view --web >/dev/null 2>&1 || gh browse >/dev/null 2>&1
