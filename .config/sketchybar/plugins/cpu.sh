#!/usr/bin/env bash

# Preferred source: macOS top aggregate CPU usage (user + sys).
CPU_PERCENT=$(
  top -l 1 -n 0 2>/dev/null | awk -F '[:,%]' '
    /CPU usage/ {
      usage = ($2 + 0) + ($4 + 0)
      printf "%.0f", usage
      exit
    }
  '
)

# Fallback: sum process CPU and normalize by logical cores.
if [ -z "$CPU_PERCENT" ]; then
  LOGICAL_CPUS=$(sysctl -n hw.logicalcpu 2>/dev/null)
  [ -z "$LOGICAL_CPUS" ] && LOGICAL_CPUS=1

  CPU_PERCENT=$(ps -A -o %cpu= 2>/dev/null | awk -v cores="$LOGICAL_CPUS" '
    {sum += $1}
    END {
      if (cores < 1) cores = 1
      printf "%.0f", sum / cores
    }
  ')
fi

[ -z "$CPU_PERCENT" ] && CPU_PERCENT=0

# Clamp noisy values.
[ "$CPU_PERCENT" -lt 0 ] && CPU_PERCENT=0
[ "$CPU_PERCENT" -gt 100 ] && CPU_PERCENT=100

sketchybar --set "$NAME" label="${CPU_PERCENT}%"
