#!/usr/bin/env bash

VM_STATS=$(vm_stat 2>/dev/null)
PAGE_SIZE=$(echo "$VM_STATS" | awk 'NR==1 {gsub("\\.","", $8); print $8}')
TOTAL_BYTES=$(sysctl -n hw.memsize 2>/dev/null)

FREE_PAGES=$(echo "$VM_STATS" | awk '/Pages free/ {gsub("\\.","", $3); print $3}')
SPEC_PAGES=$(echo "$VM_STATS" | awk '/Pages speculative/ {gsub("\\.","", $3); print $3}')
FILE_BACKED_PAGES=$(echo "$VM_STATS" | awk '/File-backed pages/ {gsub("\\.","", $3); print $3}')
PURGEABLE_PAGES=$(echo "$VM_STATS" | awk '/Pages purgeable/ {gsub("\\.","", $3); print $3}')

[ -z "$PAGE_SIZE" ] && PAGE_SIZE=4096
[ -z "$TOTAL_BYTES" ] && TOTAL_BYTES=0
[ -z "$FREE_PAGES" ] && FREE_PAGES=0
[ -z "$SPEC_PAGES" ] && SPEC_PAGES=0
[ -z "$FILE_BACKED_PAGES" ] && FILE_BACKED_PAGES=0
[ -z "$PURGEABLE_PAGES" ] && PURGEABLE_PAGES=0

# Treat reclaimable cache as available to better match "used" memory shown in Activity Monitor.
AVAILABLE_BYTES=$(( (FREE_PAGES + SPEC_PAGES + FILE_BACKED_PAGES + PURGEABLE_PAGES) * PAGE_SIZE ))
USED_BYTES=$(( TOTAL_BYTES - AVAILABLE_BYTES ))
[ "$USED_BYTES" -lt 0 ] && USED_BYTES=0

RAM_PERCENT=$(awk -v used="$USED_BYTES" -v total="$TOTAL_BYTES" '
  BEGIN {
    if (total > 0) printf "%.0f", (used / total) * 100
    else print 0
  }
')

# Clamp noisy values.
[ "$RAM_PERCENT" -lt 0 ] && RAM_PERCENT=0
[ "$RAM_PERCENT" -gt 100 ] && RAM_PERCENT=100

sketchybar --set "$NAME" label="${RAM_PERCENT}%"
