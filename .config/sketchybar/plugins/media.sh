#!/bin/bash
source "$CONFIG_DIR/plugins/icon_map.sh"

# Color Definitions
SPOTIFY_GREEN=0xff1db954
SPOTIFY_BLACK=0xff000000
APPLE_RED=0xfffc3c44
WHITE=0xffffffff

PLAYING=""

# --- 1. Spotify (Check Process First) ---
# pgrep -x ensures we only match the exact app name
if pgrep -x "Spotify" >/dev/null; then
  # Only now is it safe to use osascript
  STATE=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
  if [ "$STATE" = "playing" ]; then
    SPOT_DATA=$(osascript -e 'tell application "Spotify" to get {name of current track, artist of current track}' 2>/dev/null)
    TITLE=$(echo "$SPOT_DATA" | cut -d',' -f1)
    SINGER=$(echo "$SPOT_DATA" | cut -d',' -f2- | sed 's/^ //')

    PLAYING="playing"
    __icon_map "Spotify"
    ICON="$icon_result"
    BG_COLOR=$SPOTIFY_GREEN
    ICON_COLOR=$SPOTIFY_BLACK
    LABEL_COLOR=$SPOTIFY_BLACK
    DISPLAY_TEXT="$TITLE - $SINGER"
  fi
fi

# --- 2. Apple Music (Check Process First) ---
if [[ "$PLAYING" != "playing" ]] && pgrep -x "Music" >/dev/null; then
  STATE=$(osascript -e 'tell application "Music" to player state as string' 2>/dev/null)
  if [ "$STATE" = "playing" ]; then
    AM_DATA=$(osascript -e 'tell application "Music" to get {name of current track, artist of current track}' 2>/dev/null)
    TITLE=$(echo "$AM_DATA" | cut -d',' -f1)
    SINGER=$(echo "$AM_DATA" | cut -d',' -f2- | sed 's/^ //')

    PLAYING="playing"
    __icon_map "Music"
    ICON="$icon_result"
    BG_COLOR=$APPLE_RED
    ICON_COLOR=$WHITE
    LABEL_COLOR=$WHITE
    DISPLAY_TEXT="$SINGER - $TITLE"
  fi
fi

# --- Final Render ---
if [ "$PLAYING" = "playing" ]; then
  sketchybar --set "$NAME" \
    drawing=on \
    icon="$ICON" \
    icon.color="$ICON_COLOR" \
    label="$DISPLAY_TEXT" \
    label.color="$LABEL_COLOR" \
    background.color="$BG_COLOR"
else
  sketchybar --set "$NAME" drawing=off
fi
