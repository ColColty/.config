#!/usr/bin/env bash
# Stamp every agent pane and every space with its GitHub PR as a $pr sidebar token,
# and print the focused space's PR for the tab bar. Runs from ui.tab_bar_right every 60s.
# gh lookups are cached in ~/.cache/herdr-pr (TTL 60s) and refreshed in the background
# so this always returns fast. Cache line format: "<label>\t<url>".
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
command -v herdr >/dev/null && command -v gh >/dev/null && command -v python3 >/dev/null || exit 0

CACHE_DIR="$HOME/.cache/herdr-pr"; mkdir -p "$CACHE_DIR"
TTL=60; TOKEN_TTL_MS=180000   # tokens expire if this script stops running

lookup() {  # $1 = checkout path → prints "label\turl" (empty label if no PR)
  local dir=$1 key cache now mtime
  key=$(printf '%s' "$dir" | shasum | cut -c1-12); cache="$CACHE_DIR/$key"
  now=$(date +%s); mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
  if [ ! -f "$cache" ] || [ $((now - mtime)) -ge $TTL ]; then
    [ -d "$cache.lock" ] && [ $((now - $(stat -f %m "$cache.lock"))) -gt 120 ] && rmdir "$cache.lock" 2>/dev/null
    ( mkdir "$cache.lock" 2>/dev/null || exit 0
      trap 'rmdir "$cache.lock" 2>/dev/null' EXIT
      cd "$dir" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1 || { printf '\t' > "$cache"; exit 0; }
      gh pr view --json number,url,state,isDraft,statusCheckRollup 2>/dev/null | jq -r '
        ("#" + (.number|tostring) +
          (if .state == "MERGED" then " merged" elif .state == "CLOSED" then " closed" elif .isDraft then " draft"
           else ((.statusCheckRollup // []) as $r |
             if ($r|length) == 0 then ""
             elif ($r|any(.conclusion == "FAILURE" or .conclusion == "CANCELLED" or .conclusion == "TIMED_OUT")) then " ✕"
             elif ($r|any(.status == "IN_PROGRESS" or .status == "QUEUED" or .status == "PENDING")) then " ⏳"
             elif ($r|all(.conclusion == "SUCCESS" or .conclusion == "SKIPPED" or .conclusion == "NEUTRAL")) then " ✓"
             else "" end) end)) + "\t" + .url' > "$cache.tmp" 2>/dev/null
      [ -s "$cache.tmp" ] && mv "$cache.tmp" "$cache" || { printf '\t' > "$cache"; rm -f "$cache.tmp"; }
    ) &
  fi
  cat "$cache" 2>/dev/null
}

AGENTS=$(herdr agent list 2>/dev/null) || exit 0
SPACES=$(herdr workspace list 2>/dev/null) || exit 0

# unique dirs → cache lines, as "dir<TAB>label<TAB>url"
TABLE=$(python3 -c '
import json,sys
a=json.loads(sys.argv[1])["result"]["agents"]; w=json.loads(sys.argv[2])["result"]["workspaces"]
dirs={x.get("foreground_cwd") or x.get("cwd") for x in a} | {x["worktree"]["checkout_path"] for x in w if x.get("worktree")}
print("\n".join(sorted(d for d in dirs if d)))' "$AGENTS" "$SPACES" | while IFS= read -r d; do
  printf '%s\t%s\n' "$d" "$(lookup "$d")"
done)

# stamp tokens; print focused space's PR
python3 - "$AGENTS" "$SPACES" "$TABLE" "$TOKEN_TTL_MS" <<'PY'
import json, subprocess, sys
agents = json.loads(sys.argv[1])["result"]["agents"]
spaces = json.loads(sys.argv[2])["result"]["workspaces"]
ttl = sys.argv[4]
pr = {}
for line in sys.argv[3].splitlines():
    parts = line.split("\t")
    if len(parts) >= 2 and parts[0]:
        pr[parts[0]] = parts[1]
def stamp(kind, ident, label):
    cmd = ["herdr", kind, "report-metadata", ident, "--source", "pr-status"]
    cmd += ["--token", f"pr={label}", "--ttl-ms", ttl] if label else ["--clear-token", "pr"]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
for a in agents:
    stamp("pane", a["pane_id"], pr.get(a.get("foreground_cwd") or a.get("cwd") or "", ""))
focused = ""
for w in spaces:
    path = (w.get("worktree") or {}).get("checkout_path", "")
    label = pr.get(path, "")
    stamp("workspace", w["workspace_id"], label)
    if w.get("focused") and label:
        focused = "PR " + label
print(focused)
PY
