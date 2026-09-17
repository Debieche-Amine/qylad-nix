#!/usr/bin/env bash
# cgroup-writer.sh - Pure cgroup v2 writer (set, get, status)

set -euo pipefail

log_error() {
    echo "[cgroup-writer] Error: $1" >&2
}

log_info() {
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        echo "[cgroup-writer] $1"
    fi
}

ensure_controller_enabled() {
    local target_dir="$1"
    local controller="$2" # e.g. "cpu", "io", "memory", "pids"
    local parent_dir
    parent_dir="$(dirname "$target_dir")"

    while [[ "$parent_dir" != "/sys/fs/cgroup" && "$parent_dir" != "/" ]]; do
        if [[ -f "$parent_dir/cgroup.subtree_control" ]]; then
            if ! grep -qw "$controller" "$parent_dir/cgroup.subtree_control"; then
                echo "+$controller" > "$parent_dir/cgroup.subtree_control" 2>/dev/null || true
            fi
        fi
        parent_dir="$(dirname "$parent_dir")"
    done
}

apply_action() {
    local cgroup_path="$1"
    local action="$2"
    shift 2

    if [[ ! -d "$cgroup_path" ]]; then
        log_error "Directory '$cgroup_path' does not exist."
        return 1
    fi

    case "$action" in
        set)
            local knob="${1:-}"
            shift 1 || true
            local val="$*"
            if [[ -z "$knob" || -z "$val" ]]; then
                log_error "set requires <knob> and <value> (e.g. set cgroup.freeze 1)"
                return 1
            fi
            knob=$(basename "$knob")

            # Map shorthand knob names (e.g. 'freeze' -> 'cgroup.freeze')
            if [[ "$knob" == "freeze" || "$knob" == "kill" || "$knob" == "events" || "$knob" == "pressure" || "$knob" == "procs" ]]; then
                knob="cgroup.$knob"
            fi

            if [[ "$knob" =~ ^(cpu|memory|io|pids)\. ]]; then
                local ctrl="${BASH_REMATCH[1]}"
                ensure_controller_enabled "$cgroup_path" "$ctrl"
            fi

            if [[ -f "$cgroup_path/$knob" ]]; then
                echo "$val" > "$cgroup_path/$knob"
                log_info "Set $knob = $val on $cgroup_path"
            else
                log_error "$knob is not available at $cgroup_path"
                return 1
            fi
            ;;

        get)
            local knob="${1:-}"
            if [[ -z "$knob" ]]; then
                log_error "get requires <knob> (e.g. get cgroup.freeze or get memory.current)"
                return 1
            fi
            knob=$(basename "$knob")
            if [[ "$knob" == "freeze" || "$knob" == "kill" || "$knob" == "events" || "$knob" == "pressure" || "$knob" == "procs" ]]; then
                knob="cgroup.$knob"
            fi

            if [[ -f "$cgroup_path/$knob" ]]; then
                cat "$cgroup_path/$knob"
            else
                log_error "$knob is not available at $cgroup_path"
                return 1
            fi
            ;;

        status)
            local is_frozen="0"
            local cpu_max="max"
            local cpu_weight="100"
            local cpu_idle="0"
            local mem_curr="0"
            local mem_max="max"
            local mem_high="max"
            local pids="0"

            [[ -f "$cgroup_path/cgroup.freeze" ]] && is_frozen=$(cat "$cgroup_path/cgroup.freeze")
            [[ -f "$cgroup_path/cpu.max" ]] && cpu_max=$(cat "$cgroup_path/cpu.max")
            [[ -f "$cgroup_path/cpu.weight" ]] && cpu_weight=$(cat "$cgroup_path/cpu.weight")
            [[ -f "$cgroup_path/cpu.idle" ]] && cpu_idle=$(cat "$cgroup_path/cpu.idle")
            [[ -f "$cgroup_path/memory.current" ]] && mem_curr=$(cat "$cgroup_path/memory.current")
            [[ -f "$cgroup_path/memory.max" ]] && mem_max=$(cat "$cgroup_path/memory.max")
            [[ -f "$cgroup_path/memory.high" ]] && mem_high=$(cat "$cgroup_path/memory.high")
            [[ -f "$cgroup_path/pids.current" ]] && pids=$(cat "$cgroup_path/pids.current")

            local mem_mb=$(( mem_curr / 1024 / 1024 ))
            printf "Freeze: %s | CPU Max: %s | Weight: %s | Idle: %s | Mem: %dMB / Max: %s (High: %s) | PIDs: %s\n" \
                "$is_frozen" "$cpu_max" "$cpu_weight" "$cpu_idle" "$mem_mb" "$mem_max" "$mem_high" "$pids"
            ;;

        *)
            log_error "Unknown action '$action'"
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "Usage: cgroup-writer.sh <cgroup_path> <set|get|status> [values...]" >&2
        exit 1
    fi
    apply_action "$@"
fi
