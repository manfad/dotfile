#!/usr/bin/env bash

# Load the mapping function
source "$CONFIG_DIR/plugins/icon_map.sh"

# Get the icon for the current app ($INFO comes from sketchybar)
__icon_map "$INFO"

# Keep a stable label length so this item does not resize and push neighbors.
APP_LABEL="$INFO"
MAX_CHARS=14
if [ "${#APP_LABEL}" -gt "$MAX_CHARS" ]; then
  APP_LABEL="${APP_LABEL:0:$MAX_CHARS}..."
fi

# Update Sketchybar
sketchybar --set "$NAME" \
  icon.drawing=on \
  icon="$icon_result" \
  label="$APP_LABEL"
