#!/bin/bash
# Date shows while the mouse is over the bar, and auto-hides after HIDE_AFTER seconds
# even if the mouse stays there. Each new mouse-enter restarts the timer.
HIDE_AFTER="${CALENDAR_HIDE_AFTER:-30}"
TIMER_PID_FILE="${TMPDIR:-/tmp}/sketchybar_calendar_hide.pid"

show() { sketchybar --animate tanh 10 --set "$NAME" drawing=on label="$(date '+%a %d %b')"; }
hide() { sketchybar --animate tanh 10 --set "$NAME" drawing=off; }

cancel_timer() {
  if [ -f "$TIMER_PID_FILE" ]; then
    kill "$(cat "$TIMER_PID_FILE")" 2>/dev/null
    rm -f "$TIMER_PID_FILE"
  fi
}

start_timer() {
  cancel_timer
  (
    trap 'kill "$SLEEP_PID" 2>/dev/null; exit 0' TERM
    sleep "$HIDE_AFTER" & SLEEP_PID=$!
    wait "$SLEEP_PID"
    sketchybar --animate tanh 10 --set "$NAME" drawing=off
    rm -f "$TIMER_PID_FILE"
  ) 2>/dev/null &
  echo $! > "$TIMER_PID_FILE"
}

case "$SENDER" in
  mouse.entered.global) show; start_timer ;;
  mouse.exited.global)  cancel_timer; hide ;;
  *)                    sketchybar --set "$NAME" label="$(date '+%a %d %b')" ;;
esac
