#!/usr/bin/env bash
SOURCE_STATE=$(defaults read com.apple.HIToolbox AppleSelectedInputSources 2>/dev/null)
LAYOUT_ID=$(defaults read com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID 2>/dev/null)

if echo "$SOURCE_STATE" | grep -qiE 'Pinyin|SCIM|Hans'; then
  TEXT="拼"
else
  TEXT="A"
fi

sketchybar --set "$NAME" label="$TEXT"
