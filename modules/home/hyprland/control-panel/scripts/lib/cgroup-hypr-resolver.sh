#!/usr/bin/env bash
# cgroup-hypr-resolver.sh - Helper library to resolve Hyprland windows to cgroup v2 paths

set -euo pipefail

if [[ -z "${XDG_RUNTIME_DIR:-}" || ! -d "$XDG_RUNTIME_DIR/hypr" ]]; then
    if [[ -d "/run/user/$(id -u)/hypr" ]]; then
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi
fi

# Find active window address (excluding control panel itself)
get_active_address() {
    hyprctl clients -j 2>/dev/null | jq -r '
      [ .[] | select(.class != "hypr-control-panel" and .mapped == true) ]
      | sort_by(.focusHistoryID)
      | .[0].address // empty
    '
}

# Resolve process PID and related child processes to unique /sys/fs/cgroup paths
pid_to_cgroup() {
    local pid="$1"
    if [[ -z "$pid" || "$pid" == "null" || "$pid" -le 1 ]]; then
        return 1
    fi

    local pids=("$pid")
    if [[ -f "/proc/$pid/task/$pid/children" ]]; then
        local child
        for child in $(cat "/proc/$pid/task/$pid/children" 2>/dev/null); do
            [[ -d "/proc/$child" ]] && pids+=("$child")
        done
    fi

    for p in "${pids[@]}"; do
        if [[ -f "/proc/$p/cgroup" ]]; then
            local rel_path
            rel_path=$(sed -n 's/^0:://p' "/proc/$p/cgroup")
            if [[ -n "$rel_path" && "$rel_path" != "/" ]]; then
                local full_path="/sys/fs/cgroup${rel_path}"
                if [[ -d "$full_path" ]]; then
                    echo "$full_path"
                fi
            fi
        fi
    done | sort -u
}

# Queries hyprctl clients and filters targets based on options
# Returns lines in format: ADDRESS|PID|CLASS|WORKSPACE|CGROUP_PATH
resolve_targets() {
    local target_active=false
    local target_inactive=false
    local target_window=""
    local target_workspace=""
    local target_anchor=""
    local filter_floating=""
    local filter_fullscreen=""
    local filter_grouped=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                shift
                ;;
            --active)
                target_active=true
                shift
                ;;
            --inactive|--beside-active|--inactive-all)
                target_inactive=true
                shift
                ;;
            --window)
                target_window="$2"
                shift 2
                ;;
            --workspace)
                target_workspace="$2"
                shift 2
                ;;
            --anchor)
                target_anchor="$2"
                shift 2
                ;;
            --floating)
                filter_floating="true"
                shift
                ;;
            --tiled)
                filter_floating="false"
                shift
                ;;
            --fullscreen)
                filter_fullscreen="true"
                shift
                ;;
            --grouped)
                filter_grouped="true"
                shift
                ;;
            *)
                echo "Error: Unknown resolver option '$1'" >&2
                return 1
                ;;
        esac
    done

    local active_addr=""
    if $target_active || $target_inactive; then
        active_addr=$(get_active_address)
    fi

    local active_ws=""
    if [[ "$target_workspace" == "active" ]]; then
        active_ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.name // empty')
    fi

    local raw_clients
    raw_clients=$(hyprctl clients -j 2>/dev/null)

    if [[ -z "$raw_clients" || "$raw_clients" == "[]" ]]; then
        return 0
    fi

    local unit_sep
    unit_sep="$(printf '\x1f')"

    # Process each client JSON object in a single jq pass using ASCII Unit Separator
    echo "$raw_clients" | jq -r ".[] | [ .address // \"\", (.pid // \"\" | tostring), .class // \"\", .workspace.name // \"\", (.floating // false | tostring), (.fullscreen // 0 | tostring), (if (.grouped // [] | length) > 0 then \"true\" else \"false\" end) ] | join(\"\u001f\")" | while IFS="$unit_sep" read -r addr pid class ws_name floating fs grouped; do
        # 0. Never target control panel itself
        if [[ "$class" == "hypr-control-panel" ]]; then
            continue
        fi

        # 1. Active window filtering
        if $target_active && [[ "$addr" != "$active_addr" ]]; then
            continue
        fi

        # 2. Inactive window filtering
        if $target_inactive && [[ "$addr" == "$active_addr" ]]; then
            continue
        fi

        # 3. Specific window selector (Address, PID, or Class substring)
        if [[ -n "$target_window" ]]; then
            if [[ "$target_window" =~ ^0x ]]; then
                [[ "$addr" == "$target_window" ]] || continue
            elif [[ "$target_window" =~ ^[0-9]+$ ]]; then
                [[ "$pid" == "$target_window" ]] || continue
            else
                [[ "$class" =~ $target_window || "$addr" == "$target_window" ]] || continue
            fi
        fi

        # 4. Workspace selector (Exact match)
        if [[ -n "$target_workspace" ]]; then
            if [[ "$target_workspace" == "active" ]]; then
                [[ "$ws_name" == "$active_ws" ]] || continue
            else
                [[ "$ws_name" == "$target_workspace" ]] || continue
            fi
        fi

        # 5. Anchor selector (Prefix match e.g. 'A' matches 'A:0', 'A:1', 'A:lane', or exact 'A')
        if [[ -n "$target_anchor" ]]; then
            if [[ "$ws_name" != "$target_anchor" && "$ws_name" != "$target_anchor:"* ]]; then
                continue
            fi
        fi

        # 6. Layout filters
        if [[ -n "$filter_floating" ]]; then
            [[ "$floating" == "$filter_floating" ]] || continue
        fi
        if [[ -n "$filter_fullscreen" ]]; then
            if [[ "$filter_fullscreen" == "true" && "$fs" == "0" ]]; then continue; fi
            if [[ "$filter_fullscreen" == "false" && "$fs" != "0" ]]; then continue; fi
        fi
        if [[ -n "$filter_grouped" ]]; then
            [[ "$grouped" == "$filter_grouped" ]] || continue
        fi

        # Resolve cgroup directory paths for all related processes in window process tree
        pid_to_cgroup "$pid" | while read -r cgroup_path; do
            if [[ -n "$cgroup_path" ]]; then
                echo "${addr}|${pid}|${class}|${ws_name}|${cgroup_path}"
            fi
        done
    done
}

# Standalone execution for debugging
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    resolve_targets "$@"
fi
