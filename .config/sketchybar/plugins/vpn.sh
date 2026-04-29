#!/usr/bin/env bash

CONNECTED_SERVICE=$(
  scutil --nc list 2>/dev/null \
    | sed -n 's/.*(Connected)[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n1
)

if [ -z "$CONNECTED_SERVICE" ]; then
  # Detect Tailscale tunnel even when default route is unchanged (split tunnel).
  for utun_if in $(ifconfig -l 2>/dev/null | tr ' ' '\n' | grep '^utun'); do
    if ifconfig "$utun_if" 2>/dev/null | grep -Eq 'inet 100\.[0-9]+\.[0-9]+\.[0-9]+'; then
      CONNECTED_SERVICE="Tailscale"
      break
    fi
  done
fi

if [ -z "$CONNECTED_SERVICE" ]; then
  DEFAULT_IF=$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')
  if [[ "$DEFAULT_IF" == utun* ]]; then
    CONNECTED_SERVICE="VPN"
  fi
fi

if [ -n "$CONNECTED_SERVICE" ]; then
  sketchybar --set "$NAME" \
    drawing=on \
    icon="􃇟" \
    icon.color=0xffffffff \
    label.drawing=off
else
  sketchybar --set "$NAME" drawing=off
fi
