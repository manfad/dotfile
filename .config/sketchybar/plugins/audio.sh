#!/usr/bin/env bash

CURRENT_DEVICE=$(SwitchAudioSource -c 2>/dev/null || echo "Unknown")

if [ -n "$INFO" ]; then
  VOLUME="$INFO"
else
  VOLUME=$(osascript -e 'output volume of (get volume settings)' 2>/dev/null || echo "0")
fi

# Keep only digits in case event payload includes extra text.
VOLUME=$(printf '%s' "$VOLUME" | tr -cd '0-9')
[ -z "$VOLUME" ] && VOLUME=0

MUTED=$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)

if [ "$MUTED" = "true" ] || [ "$VOLUME" -eq 0 ]; then
  ICON="􀊣"
elif echo "$CURRENT_DEVICE" | grep -iqE "head|airpods|external|bluetooth|headphones|headset|earbuds"; then
  ICON="􀑈"
else
  ICON="􀊧"
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color=0xffffffff \
  label="${VOLUME}%" \
  label.color=0xffffffff \
  label.padding_left=4 \
  label.padding_right=6
