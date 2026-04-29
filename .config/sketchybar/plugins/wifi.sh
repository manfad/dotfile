#!/usr/bin/env bash

INTERFACE=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}')
[ -z "$INTERFACE" ] && INTERFACE="en0"

HOTSPOT_ACTIVE=false
for br in bridge100 bridge101; do
  if ifconfig "$br" 2>/dev/null | grep -q "status: active"; then
    HOTSPOT_ACTIVE=true
    break
  fi
done

SUMMARY=$(ipconfig getsummary "$INTERFACE" 2>/dev/null)
SSID=$(echo "$SUMMARY" | awk -F ' SSID : ' '/ SSID : / {print $2; exit}')
ROUTER=$(echo "$SUMMARY" | awk -F ' Router : ' '/ Router : / {print $2; exit}')

IS_CONNECTED=false
if [ -n "$SSID" ] && [ "$SSID" != "(null)" ] && [ "$SSID" != "redacted" ]; then
  IS_CONNECTED=true
fi

IS_HOTSPOT_CLIENT=false
if [ "$IS_CONNECTED" = true ]; then
  SSID_LC=$(printf '%s' "$SSID" | tr '[:upper:]' '[:lower:]')
  if [[ "$ROUTER" == "172.20.10.1" ]] || echo "$SSID_LC" | grep -Eq '(hotspot|iphone|android|pixel|galaxy|tether|personal)'; then
    IS_HOTSPOT_CLIENT=true
  fi
fi

if [ "$HOTSPOT_ACTIVE" = true ] || [ "$IS_HOTSPOT_CLIENT" = true ]; then
  ICON="􀉤"
  COLOR=0xffffffff
else
  if [ "$IS_CONNECTED" = true ]; then
    ICON="􀙇"
    COLOR=0xffffffff
  else
    if ifconfig "$INTERFACE" | grep -q "status: active"; then
      ICON="􀙇"
      COLOR=0xffffffff
    else
      ICON="􀙈"
      COLOR=0xff939ab7
    fi
  fi
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="$COLOR"
