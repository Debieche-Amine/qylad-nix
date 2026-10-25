#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

if [ "$ACTION" != "apply" ]; then
    echo "Usage: power-profile-backend apply <governor> <epp> <no_turbo> <max_perf_pct> [min_perf_pct]" >&2
    exit 1
fi

GOV="${2:-powersave}"
EPP="${3:-balance_performance}"
NO_TURBO="${4:-0}"
MAX_PERF="${5:-100}"
MIN_PERF="${6:-8}"

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

if ! [[ "$MIN_PERF" =~ ^[0-9]+$ ]] || [ "$MIN_PERF" -lt 1 ] || [ "$MIN_PERF" -gt 100 ]; then
    echo "Invalid min_perf_pct: $MIN_PERF" >&2
    exit 1
fi

# Ensure min does not exceed max
if [ "$MIN_PERF" -gt "$MAX_PERF" ]; then
    MIN_PERF="$MAX_PERF"
fi

# Apply Turbo toggle first so driver limits reflect turbo state
if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo "$NO_TURBO" > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
fi

# Apply Governor
for p in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "$p" ] && echo "$GOV" > "$p" 2>/dev/null || true
done

# Apply EPP
for p in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
    [ -f "$p" ] && echo "$EPP" > "$p" 2>/dev/null || true
done

# Detect hardware frequency boundaries (in kHz)
BASE_KHZ="$(cat /sys/devices/system/cpu/cpu0/cpufreq/base_frequency 2>/dev/null || echo 1100000)"
CPUINFO_MIN="$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null || echo 400000)"
TURBO_MAX_KHZ="4700000"
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ]; then
    CURR_INFO_MAX="$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 0)"
    if [ "$CURR_INFO_MAX" -gt "$TURBO_MAX_KHZ" ]; then
        TURBO_MAX_KHZ="$CURR_INFO_MAX"
    fi
fi

# Calculate frequency ceilings and floors in kHz
if [ "$NO_TURBO" = "1" ]; then
    TARGET_MAX_KHZ=$(( TURBO_MAX_KHZ * MAX_PERF / 100 ))
    if [ "$TARGET_MAX_KHZ" -gt "$BASE_KHZ" ]; then
        TARGET_MAX_KHZ="$BASE_KHZ"
    fi
else
    TARGET_MAX_KHZ=$(( TURBO_MAX_KHZ * MAX_PERF / 100 ))
    if [ "$TARGET_MAX_KHZ" -gt "$TURBO_MAX_KHZ" ]; then
        TARGET_MAX_KHZ="$TURBO_MAX_KHZ"
    fi
fi

TARGET_MIN_KHZ=$(( TURBO_MAX_KHZ * MIN_PERF / 100 ))
if [ "$TARGET_MIN_KHZ" -lt "$CPUINFO_MIN" ]; then
    TARGET_MIN_KHZ="$CPUINFO_MIN"
fi
if [ "$TARGET_MIN_KHZ" -gt "$TARGET_MAX_KHZ" ]; then
    TARGET_MIN_KHZ="$TARGET_MAX_KHZ"
fi

# Apply cpufreq scaling_min_freq and scaling_max_freq across all cores safely
for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
    [ -d "$cpu" ] || continue
    # Expand max first to avoid rejection when raising min above previous max
    echo "$TURBO_MAX_KHZ" > "$cpu/scaling_max_freq" 2>/dev/null || true
    echo "$TARGET_MIN_KHZ" > "$cpu/scaling_min_freq" 2>/dev/null || true
    echo "$TARGET_MAX_KHZ" > "$cpu/scaling_max_freq" 2>/dev/null || true
    echo "$TARGET_MIN_KHZ" > "$cpu/scaling_min_freq" 2>/dev/null || true
done

# Apply driver-level intel_pstate min and max perf pct safely in bidirectional order
if [ -f /sys/devices/system/cpu/intel_pstate/min_perf_pct ] && [ -f /sys/devices/system/cpu/intel_pstate/max_perf_pct ]; then
    echo "$MIN_PERF" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
    echo "$MAX_PERF" > /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || true
    echo "$MIN_PERF" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
fi
