#!/bin/bash
# Runs the Shortcut "AirPods <Mode>" (create these in Shortcuts.app with the
# "Set Noise Control Mode" action). Falls back to Bluetooth settings.
MODE="$1"
if shortcuts list 2>/dev/null | grep -qx "AirPods $MODE"; then
  shortcuts run "AirPods $MODE"
else
  open 'x-apple.systempreferences:com.apple.BluetoothSettings'
fi
