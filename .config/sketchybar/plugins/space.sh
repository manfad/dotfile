#!/bin/bash

# When a space is active, $SELECTED is "true"
if [ "$SELECTED" = "true" ]; then
  sketchybar --set $NAME background.drawing=on \
                         icon.highlight=off \
                         icon.color=0xffffffff  # White (or your active color)
else
  sketchybar --set $NAME background.drawing=off \
                         icon.highlight=off \
                         icon.color=0xff888888  # Gray (inactive color)
fi