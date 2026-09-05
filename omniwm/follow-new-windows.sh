#!/bin/bash
# Follow newly opened windows to the workspace an app rule sent them to, the way
# AeroSpace did. OmniWM keeps you where you are, so: watch window events and, when
# a window we have not seen before lands on another workspace, switch there if it
# looks user-initiated: the app's process started in the last few seconds (you
# launched it), or OmniWM just reported losing focus (macOS activated a window it
# is not showing). Run by launchd (KeepAlive).
export PATH="/opt/homebrew/bin:$PATH"
STATE="$(cd "$(dirname "$0")" && pwd)/.state"; mkdir -p "$STATE"
KNOWN=$(omniwmctl query windows --format json 2>/dev/null | jq -r '[.. | objects | select(has("windowId"))] | .[].id')
last_focus_lost=0
started_recently() {  # pid started < 6s ago
  local e; e=$(ps -o etime= -p "$1" 2>/dev/null | tr -d ' '); [ -n "$e" ] || return 1
  [[ "$e" == *-* ]] && return 1                       # days
  local IFS=:; set -- $e; local secs=0
  for part in "$@"; do secs=$((secs * 60 + 10#$part)); done
  [ "$secs" -lt 6 ]
}

omniwmctl subscribe windows-changed,focus --no-send-initial --reconnect --format ndjson 2>/dev/null \
| while IFS= read -r line; do
    case "$line" in
      *'"channel":"focus"'*)
        # focused-window with no window: focus went to something OmniWM is not showing
        if jq -e '.result.payload.window == null' <<<"$line" >/dev/null 2>&1; then last_focus_lost=$(date +%s)
        else  # remember the last focused window per workspace, for focus.sh's floating fallback
          IFS=$'\t' read -r fid fws <<<"$(jq -r '.result.payload.window | [.id, .workspace.number] | @tsv' <<<"$line" 2>/dev/null)"
          [ -n "$fid" ] && [ -n "$fws" ] && echo "$fid" >"$STATE/last-focus-$fws"
        fi
        continue ;;
      *'"windows"'*) ;;
      *) continue ;;
    esac
    current=$(omniwmctl query active-workspace --format json 2>/dev/null | jq -r '[.. | objects | select(has("number"))][0].number')
    while IFS=$'\t' read -r id pid ws; do
      [ -n "$id" ] || continue
      grep -qx "$id" <<<"$KNOWN" && continue
      KNOWN="$KNOWN"$'\n'"$id"
      [ -n "$ws" ] && [ "$ws" != "$current" ] || continue
      if started_recently "$pid" || [ $(( $(date +%s) - last_focus_lost )) -le 2 ]; then
        omniwmctl command switch-workspace "$ws" >/dev/null 2>&1
        current=$ws
      fi
    done < <(jq -r '.result.payload.windows[]? | [.id, .pid, .workspace.number] | @tsv' <<<"$line" 2>/dev/null)
    live=$(jq -r '.result.payload.windows[]?.id' <<<"$line" 2>/dev/null)
    [ -n "$live" ] && KNOWN=$(grep -Fxf <(echo "$live") <<<"$KNOWN")
  done
