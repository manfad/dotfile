#!/usr/bin/env bash

CALENDAR_ICONS=(
  "􃌦" "􃌧" "􃌨" "􃌩" "􃌪" "􃌫" "􃌬" "􃌭" "􃌮" "􃌯" "􃌰"
  "􃌱" "􃌲" "􃌳" "􃌴" "􃌵" "􃌶" "􃌷" "􃌸" "􃌹" "􃌺" "􃌻"
  "􃌼" "􃌽" "􃌾" "􃌿" "􃍀" "􃍁" "􃍂" "􃍃" "􃍄"
)

DAY_OF_MONTH=$(date +%-d)
ICON_INDEX=$((DAY_OF_MONTH - 1))
ICON="${CALENDAR_ICONS[$ICON_INDEX]}"
TEXT="$(date '+%a %-d %b')"

sketchybar --set "$NAME" \
  icon="$ICON" \
  label="$TEXT"

  
