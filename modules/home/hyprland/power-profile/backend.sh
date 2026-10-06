#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

if [ "$ACTION" != "apply" ]; then
    echo "Usage: power-profile-backend apply <governor> <epp> <no_turbo> <max_perf_pct>" >&2
    exit 1
fi

GOV="${2:-powersave}"
EPP="${3:-balance_performance}"
NO_TURBO="${4:-0}"
MAX_PERF="${5:-100}"

# Validate inputs
if [[ "$GOV" != "performance" && "$GOV" != "powersave" ]]; then
    echo "Invalid governor: $GOV" >&2
    exit 1
fi

case "$EPP" in
    performance|balance_performance|balance_power|power|default) ;;
    *) echo "Invalid EPP: $EPP" >&2; exit 1 ;;
esac

if [[ "$NO_TURBO" != "0" && "$NO_TURBO" != "1" ]]; then
    echo "Invalid no_turbo: $NO_TURBO" >&2
    exit 1
fi

if ! [[ "$MAX_PERF" =~ ^[0-9]+$ ]] || [ "$MAX_PERF" -lt 1 ] || [ "$MAX_PERF" -gt 100 ]; then
    echo "Invalid max_perf_pct: $MAX_PERF" >&2
    exit 1
fi

# Apply Governor
for p in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "$p" ] && echo "$GOV" > "$p" 2>/dev/null || true
done

# Apply EPP
for p in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
    [ -f "$p" ] && echo "$EPP" > "$p" 2>/dev/null || true
done

# Apply Turbo
if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo "$NO_TURBO" > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
fi

# Apply Max Perf Pct
if [ -f /sys/devices/system/cpu/intel_pstate/max_perf_pct ]; then
    echo "$MAX_PERF" > /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || true
fi
