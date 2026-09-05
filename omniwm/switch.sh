#!/bin/bash
# Cut over between AeroSpace and OmniWM.
#   switch.sh to-omniwm   quit AeroSpace, start OmniWM, port the config, swap Sketchybar + Karabiner
#   switch.sh back        the reverse
# Everything is reversible; AeroSpace's config is left intact apart from start-at-login.
export PATH="/opt/homebrew/bin:$PATH"
DIR="$(cd "$(dirname "$0")" && pwd)"
SB="$HOME/.config/sketchybar"
KB="$HOME/.config/karabiner/karabiner.json"
AERO="$HOME/.config/aerospace/aerospace.toml"
RULE_DESC=$(jq -r .description "$DIR/karabiner-rule.json")
say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

karabiner_add() {
  python3 - "$KB" "$DIR/karabiner-rule.json" <<'PY'
import json, sys
kb, rule = sys.argv[1], json.load(open(sys.argv[2]))
d = json.load(open(kb))
prof = next((p for p in d["profiles"] if p.get("selected")), d["profiles"][0])
rules = prof.setdefault("complex_modifications", {}).setdefault("rules", [])
if not any(r.get("description") == rule["description"] for r in rules):
    rules.insert(0, rule); json.dump(d, open(kb, "w"), indent=4); print("karabiner: rule added (Karabiner reloads on its own)")
else:
    print("karabiner: rule already present")
PY
}
karabiner_remove() {
  python3 - "$KB" "$RULE_DESC" <<'PY'
import json, sys
kb, desc = sys.argv[1], sys.argv[2]
d = json.load(open(kb)); n = 0
for p in d["profiles"]:
    rules = p.get("complex_modifications", {}).get("rules", [])
    keep = [r for r in rules if r.get("description") != desc]; n += len(rules) - len(keep)
    if "complex_modifications" in p: p["complex_modifications"]["rules"] = keep
json.dump(d, open(kb, "w"), indent=4); print(f"karabiner: {n} rule(s) removed")
PY
}

to_omniwm() {
  say "1/6 AeroSpace: drop its login item, then quit it"
  sed -i '' 's/^start-at-login = true/start-at-login = false/' "$AERO"
  aerospace reload-config 2>/dev/null; sleep 0.5
  osascript -e 'quit app "AeroSpace"' 2>/dev/null; sleep 1; pkill -x AeroSpace 2>/dev/null
  pgrep -x AeroSpace >/dev/null && echo "AeroSpace still running?!" || echo "AeroSpace stopped"

  say "2/6 OmniWM: launching. Grant Accessibility and Input Monitoring when macOS asks (Screen Recording is optional: skip it)."
  open -a /Applications/OmniWM.app
  for i in $(seq 1 300); do [ -f "$DIR/settings.toml" ] && break; sleep 1; done
  if [ ! -f "$DIR/settings.toml" ]; then
    echo "settings.toml was not written after 5 min. Open OmniWM's menu bar icon > Settings once (that writes the file), then re-run: $0 to-omniwm"; exit 1
  fi
  sleep 2

  say "3/6 Port the AeroSpace config into settings.toml"
  python3 "$DIR/port-from-aerospace.py" || { echo "port failed; settings restored from backup"; exit 1; }

  say "4/6 Sketchybar: workspaces from omniwmctl, no binding-mode item"
  cp "$DIR/sketchybar/items/omniwm.sh" "$SB/items/omniwm.sh"
  cp "$DIR/sketchybar/plugins/omniwm.sh" "$SB/plugins/omniwm.sh"
  sed -i '' -e 's|^source "\$ITEM_DIR/aerospace.sh"|source "$ITEM_DIR/omniwm.sh"|' \
            -e 's|^source "\$ITEM_DIR/mode.sh"|# source "$ITEM_DIR/mode.sh"   # AeroSpace binding modes; unused under OmniWM|' "$SB/sketchybarrc"
  echo "sketchybarrc swapped (hotload reloads the bar; if items land out of order, that is the known reload quirk)"

  say "5/6 Karabiner: Option+Return / Option+0 / Option+Shift+0 / Option+Shift+F / Option+M"
  karabiner_add
  sed "s|\$HOME|$HOME|g" "$DIR/launchd/com.tforne.omniwm-follow.plist" >"$HOME/Library/LaunchAgents/com.tforne.omniwm-follow.plist"
  launchctl bootstrap gui/$(id -u) "$HOME/Library/LaunchAgents/com.tforne.omniwm-follow.plist" 2>/dev/null \
    && echo "follow-new-windows agent loaded (switch to the workspace a rule sends a new app to)"

  say "6/6 Left for you"
  osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -q OmniWM \
    && echo "  - Start at Login: already registered by OmniWM." \
    || echo "  - OmniWM menu bar icon > Settings > General > Startup: enable Start at Login."
  cat <<TXT
  - Test: alt+h/j/k/l focus, alt+shift+h/j/k/l move, alt+1..9 / alt+0 workspaces, alt+[ ] prev/next,
    alt+tab back-and-forth, alt+w tabbed column, alt+e layout toggle, alt+f fullscreen,
    alt+shift+f float 60%, alt+m centre, alt+minus / alt+shift+minus scratchpad 1, alt+q close, alt+enter terminal.
  - With the MacBook display active, run: python3 $DIR/port-from-aerospace.py   (adds its zero top gap)
  - Revert any time: $0 back
TXT
}

back() {
  say "1/4 OmniWM: quit"
  osascript -e 'quit app "OmniWM"' 2>/dev/null; sleep 1; pkill -x OmniWM 2>/dev/null
  osascript -e 'tell application "System Events" to delete login item "OmniWM"' 2>/dev/null
  launchctl bootout gui/$(id -u)/com.tforne.omniwm-follow 2>/dev/null
  pkill -f 'omniwmctl watch' 2>/dev/null
  say "2/4 Karabiner: remove the OmniWM rule"; karabiner_remove
  say "3/4 Sketchybar: back to the aerospace items"
  sed -i '' -e 's|^source "\$ITEM_DIR/omniwm.sh"|source "$ITEM_DIR/aerospace.sh"|' \
            -e 's|^# source "\$ITEM_DIR/mode.sh".*|source "$ITEM_DIR/mode.sh"|' "$SB/sketchybarrc"
  say "4/4 AeroSpace: start-at-login back on, launch"
  sed -i '' 's/^start-at-login = false/start-at-login = true/' "$AERO"
  open -a /Applications/AeroSpace.app
  echo "done. OmniWM stays installed; its settings are in $DIR/settings.toml"
}

case "$1" in
  to-omniwm) to_omniwm ;;
  back)      back ;;
  *) echo "usage: $0 to-omniwm|back"; exit 1 ;;
esac
