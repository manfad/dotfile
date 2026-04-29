#!/bin/sh

BATTERY_INFO=$(pmset -g batt)
BATTERY_LINE=$(printf '%s\n' "$BATTERY_INFO" | grep '%')
PERCENTAGE=$(printf '%s\n' "$BATTERY_LINE" | grep -Eo '[0-9]+%' | cut -d% -f1)
STATE=$(printf '%s\n' "$BATTERY_LINE" | cut -d';' -f2 | xargs)

if [ -z "$PERCENTAGE" ]; then
  exit 0
fi

COLOR=0xffffffff

case ${PERCENTAGE} in
  100|9[0-9])
    ICON="􀛨"
  ;;
  [6-8][0-9])
    ICON="􀺸"
  ;;
  [4-5][0-9])
    ICON="􀺶"
    COLOR=0xffffd60a # Yellow near 50%
  ;;
  [2-3][0-9])
    ICON="􀛩"
    COLOR=0xffed8796 # Red when low
  ;;
  *)
    ICON="􀛪"
    COLOR=0xffed8796 # Red when critical
esac

# Only show the charging icon for explicit charging states.
case "$STATE" in
  charging|"finishing charge"|charged|"AC attached")
  ICON="􀢋"
  COLOR=0xffa6da95
  ;;
esac

sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" icon.color="$COLOR"
