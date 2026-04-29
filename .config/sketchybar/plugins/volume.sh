#!/usr/bin/env bash

CURRENT=$(SwitchAudioSource -c 2>/dev/null) # suppress errors

if [ -z "$CURRENT" ]; then
  ICON="􀊢"         # fallback question mark or no-audio icon
  COLOR=0xffffffff # white
elif [[ $CURRENT == *"Head"* || $CURRENT == *"AirPods"* || $CURRENT == *"External"* || $CURRENT == *"Bluetooth"* ]]; then
  ICON="􀑈" # headset / headphones
  COLOR=0xffffffff
else
  ICON="􀊦" # built-in speaker
  COLOR=0xffffffff
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR"

