#!/usr/bin/env python3
"""
Hyprland Cgroup & Window Control Panel
Full-featured TUI HUD for Linux cgroup v2 resource management and Hyprland window control.

Tabs:
  [1: Windows & Resources] - Dual-pane live process matrix & real-time cgroup inspector
  [2: System Profiles]     - One-click workflow profiles (Game Mode, Dev Mode, Battery Saver)
"""

import os
import sys

# Eliminate standard 1000ms ncurses ESC key delay
os.environ.setdefault("ESCDELAY", "25")

import curses
import json
import shutil
import signal
import subprocess
import textwrap
import threading
import time

HYPRCTL = shutil.which("hyprctl") or "hyprctl"
NOTIFY_SEND = shutil.which("notify-send") or "notify-send"


def get_hypr_env():
    """Detects active Hyprland runtime directory and instance signature."""
    env = dict(os.environ)
    runtime = env.get("XDG_RUNTIME_DIR", "")
    uid = os.getuid()
    cand = f"/run/user/{uid}"

    if not runtime or not os.path.exists(f"{runtime}/hypr"):
        if os.path.exists(f"{cand}/hypr"):
            env["XDG_RUNTIME_DIR"] = cand
            runtime = cand

    if runtime and os.path.exists(f"{runtime}/hypr"):
        sig = env.get("HYPRLAND_INSTANCE_SIGNATURE", "")
        if not sig or not os.path.exists(f"{runtime}/hypr/{sig}"):
            try:
                entries = [
                    d
                    for d in os.listdir(f"{runtime}/hypr")
                    if os.path.isdir(f"{runtime}/hypr/{d}")
                    and os.path.exists(f"{runtime}/hypr/{d}/.socket.sock")
                ]
                if entries:
                    entries.sort(
                        key=lambda d: os.path.getmtime(f"{runtime}/hypr/{d}"),
                        reverse=True,
                    )
                    env["HYPRLAND_INSTANCE_SIGNATURE"] = entries[0]
            except Exception:
                pass
    return env


def notify(title, msg, urgency="normal"):
    """Dispatches desktop notification asynchronously to avoid blocking the TUI."""
    if NOTIFY_SEND:
        try:
            subprocess.Popen(
                [NOTIFY_SEND, "-a", "Control Panel", "-u", urgency, title, msg],
                env=get_hypr_env(),
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            pass


def hypr_dispatch(cmd, *args):
    """Executes a Hyprland dispatcher command."""
    try:
        call = [HYPRCTL, "dispatch", cmd]
        if args:
            call.extend(args)
        subprocess.Popen(
            call,
            env=get_hypr_env(),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except Exception:
        return False


def focus_window_and_switch(client):
    """Switches workspace in Hyprland (including special workspaces) and focuses window."""
    addr = client.get("address")
    if not addr:
        return
    ws = client.get("workspace", {}).get("name", "")
    env = get_hypr_env()
    if ws.startswith("special:"):
        s_name = ws.replace("special:", "")
        subprocess.run([HYPRCTL, "dispatch", "togglespecialworkspace", s_name], capture_output=True, env=env)
    elif ws:
        subprocess.run([HYPRCTL, "dispatch", "workspace", f"name:{ws}"], capture_output=True, env=env)
    subprocess.run([HYPRCTL, "dispatch", "focuswindow", f"address:{addr}"], capture_output=True, env=env)


def ensure_cgroup_controllers():
    """Ensures cpu, memory, and io controllers are enabled in all ancestor user slices."""
    uid = os.getuid()
    slices_to_check = [
        f"/sys/fs/cgroup/user.slice/user-{uid}.slice",
        f"/sys/fs/cgroup/user.slice/user-{uid}.slice/user@{uid}.service",
        f"/sys/fs/cgroup/user.slice/user-{uid}.slice/user@{uid}.service/app.slice",
        f"/sys/fs/cgroup/user.slice/user-{uid}.slice/user@{uid}.service/app.slice/app-graphical.slice",
    ]
    for p in slices_to_check:
        sub_ctrl = f"{p}/cgroup.subtree_control"
        ctrl_file = f"{p}/cgroup.controllers"
        if os.path.exists(sub_ctrl) and os.path.exists(ctrl_file):
            try:
                available = set(open(ctrl_file).read().split())
                enabled = set(open(sub_ctrl).read().split())
                for c in ("cpu", "memory", "io"):
                    if c in available and c not in enabled:
                        with open(sub_ctrl, "w") as f:
                            f.write(f"+{c}\n")
            except Exception:
                pass


def fmt_mem_val(raw):
    """Formats raw bytes or string into human readable MB/GB."""
    if not raw or raw == "max":
        return "max"
    if str(raw).isdigit():
        mb = int(raw) // (1024 * 1024)
        if mb >= 1024 and mb % 1024 == 0:
            return f"{mb // 1024}G"
        return f"{mb}M"
    return str(raw)


def workspace_sort_key(ws_name):
    """Sorts anchor workspaces first (A:0, A:1, A:-1...), then numbered, then special."""
    if ws_name.startswith("special:"):
        return (2, ws_name)
    elif ":" in ws_name:
        parts = ws_name.split(":")
        lane = parts[0].upper()
        offset = parts[1]
        try:
            off_num = int(offset)
            off_rank = 0 if off_num == 0 else (1 if off_num > 0 else 2), abs(off_num)
        except ValueError:
            off_rank = (3, offset)
        return (0, lane, off_rank)
    else:
        try:
            return (1, int(ws_name))
        except ValueError:
            return (1, ws_name)


def parse_workspace_lane(ws_name):
    """Returns (lane_key, lane_label, ws_key, ws_label, ws_rank) for 2-level hierarchy."""
    ws = str(ws_name or "1")
    if ws.startswith("special:"):
        s_name = ws.replace("special:", "")
        return (
            "SPECIAL",
            "󰍹 SPECIAL WORKSPACES",
            ws,
            f"󰍹 SPECIAL [{s_name}]",
            (2, s_name),
        )
    elif ":" in ws:
        parts = ws.split(":", 1)
        lane_char = parts[0].upper()
        offset_str = parts[1]
        try:
            off_num = int(offset_str)
            off_rank = 0 if off_num == 0 else (1 if off_num > 0 else 2), abs(off_num)
        except ValueError:
            off_rank = (3, offset_str)
        return (
            lane_char,
            f"󰋼 ANCHOR LANE [{lane_char}]",
            ws,
            f"󰍹 WORKSPACE [{ws}]",
            (0, lane_char, off_rank),
        )
    else:
        try:
            num = int(ws)
            return (
                "NUMBERED",
                "󰍹 NUMBERED WORKSPACES",
                ws,
                f"󰍹 WORKSPACE [{ws}]",
                (1, num),
            )
        except ValueError:
            return (
                "NUMBERED",
                "󰍹 NUMBERED WORKSPACES",
                ws,
                f"󰍹 WORKSPACE [{ws}]",
                (1, ws),
            )


_PID_CGROUP_CACHE = {}


def get_cgroups_for_pid(pid):
    """Resolves process PID and all related child scopes with fast in-memory caching."""
    if not pid or pid <= 1:
        return []

    cached = _PID_CGROUP_CACHE.get(pid)
    if cached is not None:
        if not cached or os.path.isdir(f"/sys/fs/cgroup{cached[0]}"):
            return cached

    cgroups = set()
    visited_pids = set()
    to_visit = [pid]

    while to_visit:
        curr = to_visit.pop()
        if curr in visited_pids or curr <= 1:
            continue
        visited_pids.add(curr)

        cg_file = f"/proc/{curr}/cgroup"
        if os.path.exists(cg_file):
            try:
                with open(cg_file, "r") as f:
                    for line in f:
                        if line.startswith("0::"):
                            rel = line.strip()[3:]
                            if rel and rel != "/":
                                cgroups.add(rel)
                            break
            except Exception:
                pass

        # If we found an app scope, no need to traverse deep process tree
        if not any("app-Hyprland" in cg for cg in cgroups):
            children_file = f"/proc/{curr}/task/{curr}/children"
            if os.path.exists(children_file):
                try:
                    with open(children_file, "r") as f:
                        for p in f.read().split()[:10]:
                            try:
                                to_visit.append(int(p))
                            except ValueError:
                                pass
                except Exception:
                    pass

    res = sorted(list(cgroups))
    _PID_CGROUP_CACHE[pid] = res
    return res


def write_cgroup_knob(cg_rel, knob, val):
    """Directly writes value to a cgroup knob in sysfs."""
    cg_path = f"/sys/fs/cgroup{cg_rel}"
    if not os.path.isdir(cg_path):
        return False, f"Directory not found: {cg_rel}"

    if knob in ("freeze", "kill", "events", "pressure", "procs"):
        knob = f"cgroup.{knob}"

    target = f"{cg_path}/{knob}"
    if not os.path.exists(target):
        return False, f"{knob} not available in {cg_rel}"

    try:
        with open(target, "w") as f:
            f.write(f"{val}\n")
        return True, "OK"
    except PermissionError:
        return False, f"Permission denied writing {knob}"
    except Exception as e:
        return False, str(e)


def read_psi_stat(cg_path, resource):
    """Reads Pressure Stall Information (PSI) for cpu, memory, or io."""
    psi_file = f"{cg_path}/{resource}.pressure"
    if os.path.exists(psi_file):
        try:
            with open(psi_file, "r") as f:
                for line in f:
                    if line.startswith("some"):
                        parts = line.split()
                        return parts[1].split("=")[1]  # avg10
        except Exception:
            pass
    return "0.0"


def read_cgroup_info_for_window(client):
    """Reads comprehensive cgroup info aggregating across all associated scopes of a window."""
    info = {
        "cgroups": [],
        "freeze": "0",
        "cpu_max": "max",
        "cpu_max_pct": 100,
        "cpu_weight": "100",
        "cpu_idle": "0",
        "mem_curr": 0,
        "mem_high": "max",
        "mem_max": "max",
        "pids": 1,
        "psi_cpu": "0.0",
        "psi_mem": "0.0",
        "psi_io": "0.0",
    }
    pid = client.get("pid", 0)
    if not pid or pid <= 1:
        return info

    cgs = get_cgroups_for_pid(pid)
    info["cgroups"] = cgs
    if not cgs:
        return info

    total_mem = 0
    total_pids = 0
    is_frozen = False
    cpu_idle = False
    cpu_max_val = "max"
    cpu_max_pct = 100
    cpu_weight_val = "100"
    mem_high_val = "max"
    mem_max_val = "max"
    psi_cpu_val = "0.0"
    psi_mem_val = "0.0"
    psi_io_val = "0.0"

    for cg in cgs:
        cg_path = f"/sys/fs/cgroup{cg}"
        if not os.path.isdir(cg_path):
            continue

        if os.path.exists(f"{cg_path}/cgroup.freeze"):
            try:
                with open(f"{cg_path}/cgroup.freeze") as f:
                    if f.read().strip() == "1":
                        is_frozen = True
            except Exception:
                pass

        if os.path.exists(f"{cg_path}/cpu.max"):
            try:
                with open(f"{cg_path}/cpu.max") as f:
                    val = f.read().strip()
                    if val and val != "max 100000":
                        cpu_max_val = val
                        quota = val.split()[0]
                        if quota.isdigit():
                            cpu_max_pct = min(100, max(1, int(quota) // 1000))
            except Exception:
                pass

        if os.path.exists(f"{cg_path}/cpu.weight"):
            try:
                with open(f"{cg_path}/cpu.weight") as f:
                    val = f.read().strip()
                    if val != "100":
                        cpu_weight_val = val
            except Exception:
                pass

        if os.path.exists(f"{cg_path}/cpu.idle"):
            try:
                with open(f"{cg_path}/cpu.idle") as f:
                    if f.read().strip() == "1":
                        cpu_idle = True
            except Exception:
                pass

        peak_mem = 0
        if os.path.exists(f"{cg_path}/memory.current"):
            try:
                with open(f"{cg_path}/memory.current") as f:
                    v = f.read().strip()
                    if v.isdigit():
                        total_mem += int(v)
            except Exception:
                pass

        if os.path.exists(f"{cg_path}/memory.peak"):
            try:
                with open(f"{cg_path}/memory.peak") as f:
                    v = f.read().strip()
                    if v.isdigit():
                        peak_mem += int(v)
            except Exception:
                pass

        if os.path.exists(f"{cg_path}/memory.high"):
            try:
                with open(f"{cg_path}/memory.high") as f:
                    v = f.read().strip()
                    if v != "max":
                        mem_high_val = v
            except Exception:
                pass

        if os.path.exists(f"{cg_path}/memory.max"):
            try:
                with open(f"{cg_path}/memory.max") as f:
                    v = f.read().strip()
                    if v != "max":
                        mem_max_val = v
            except Exception:
                pass

        if os.path.exists(f"{cg_path}/pids.current"):
            try:
                with open(f"{cg_path}/pids.current") as f:
                    v = f.read().strip()
                    if v.isdigit():
                        total_pids += int(v)
            except Exception:
                pass

        # Read PSI stats
        p_c = read_psi_stat(cg_path, "cpu")
        if p_c != "0.0":
            psi_cpu_val = p_c
        p_m = read_psi_stat(cg_path, "memory")
        if p_m != "0.0":
            psi_mem_val = p_m
        p_i = read_psi_stat(cg_path, "io")
        if p_i != "0.0":
            psi_io_val = p_i

    info["freeze"] = "1" if is_frozen else "0"
    info["cpu_max"] = cpu_max_val
    info["cpu_max_pct"] = cpu_max_pct
    info["cpu_weight"] = cpu_weight_val
    info["cpu_idle"] = "1" if cpu_idle else "0"
    info["mem_curr"] = total_mem // (1024 * 1024)
    info["mem_peak"] = max(info["mem_curr"], peak_mem // (1024 * 1024))
    info["mem_high"] = mem_high_val
    info["mem_high_disp"] = fmt_mem_val(mem_high_val)
    info["mem_max"] = mem_max_val
    info["mem_max_disp"] = fmt_mem_val(mem_max_val)
    info["pids"] = max(1, total_pids)
    info["psi_cpu"] = psi_cpu_val
    info["psi_mem"] = psi_mem_val
    info["psi_io"] = psi_io_val
    return info


def apply_knob_to_window(client, knob, val):
    """Applies a knob to all cgroups resolved for a client."""
    cgs = client.get("_cgroups") or get_cgroups_for_pid(client.get("pid", 0))
    if not cgs:
        return False, "No cgroup found for process"

    ensure_cgroup_controllers()
    success = False
    last_err = ""
    for cg in cgs:
        ok, msg = write_cgroup_knob(cg, knob, val)
        if ok:
            success = True
        else:
            last_err = msg
    return success, last_err or "OK"


def reset_window_limits(client):
    """Restores all limits (CPU quota, weight, idle, freeze, memory.high, memory.max) to defaults."""
    ensure_cgroup_controllers()
    knobs = [
        ("cgroup.freeze", "0"),
        ("cpu.max", "max 100000"),
        ("cpu.weight", "100"),
        ("cpu.idle", "0"),
        ("memory.high", "max"),
        ("memory.max", "max"),
        ("memory.swap.max", "max"),
    ]
    cgs = client.get("_cgroups") or get_cgroups_for_pid(client.get("pid", 0))
    for cg in cgs:
        for k, v in knobs:
            write_cgroup_knob(cg, k, v)


def kill_window_process_tree(client):
    """Sends cgroup.kill to terminate all processes in the scope."""
    cgs = client.get("_cgroups") or get_cgroups_for_pid(client.get("pid", 0))
    killed = False
    for cg in cgs:
        ok, _ = write_cgroup_knob(cg, "cgroup.kill", "1")
        if ok:
            killed = True

    pid = client.get("pid", 0)
    if pid > 1:
        try:
            os.kill(pid, signal.SIGTERM)
            killed = True
        except Exception:
            pass
    return killed


def get_hypr_clients():
    """Returns sorted, valid Hyprland clients excluding hypr-control-panel."""
    try:
        proc = subprocess.run(
            [HYPRCTL, "clients", "-j"],
            capture_output=True,
            text=True,
            env=get_hypr_env(),
        )
        if proc.returncode == 0 and proc.stdout:
            data = json.loads(proc.stdout)
            clients = [
                c
                for c in data
                if c.get("class") != "hypr-control-panel"
                and c.get("mapped") is not False
                and c.get("pid", 0) > 0
            ]
            return clients
    except Exception:
        pass
    return []


def get_hypr_active_client(clients):
    """Finds the active client (the one focused before control panel was opened)."""
    if clients:
        sorted_clients = sorted(clients, key=lambda c: c.get("focusHistoryID", 9999))
        return sorted_clients[0].get("address")
    return None


def get_hypr_workspaces():
    try:
        proc = subprocess.run(
            [HYPRCTL, "workspaces", "-j"],
            capture_output=True,
            text=True,
            env=get_hypr_env(),
        )
        if proc.returncode == 0 and proc.stdout:
            ws_data = json.loads(proc.stdout)
            return sorted(
                list(set(w.get("name", "") for w in ws_data if w.get("name")))
            )
    except Exception:
        pass
    return []


def get_hypr_active_workspace():
    """Queries Hyprland for the currently active workspace name."""
    try:
        proc = subprocess.run(
            [HYPRCTL, "activeworkspace", "-j"],
            capture_output=True,
            text=True,
            env=get_hypr_env(),
        )
        if proc.returncode == 0 and proc.stdout:
            data = json.loads(proc.stdout)
            return data.get("name", "")
    except Exception:
        pass
    return ""


def read_window_io(pid, cgroups):
    """Reads physical disk bytes and total syscall transfer."""
    rb, wb, rc, wc = 0, 0, 0, 0
    if cgroups:
        for cg in cgroups:
            cg_path = f"/sys/fs/cgroup{cg}"
            if os.path.exists(f"{cg_path}/io.stat"):
                try:
                    with open(f"{cg_path}/io.stat", "r") as f:
                        for line in f:
                            for part in line.split():
                                if part.startswith("rbytes="):
                                    rb += int(part.split("=")[1])
                                elif part.startswith("wbytes="):
                                    wb += int(part.split("=")[1])
                except Exception:
                    pass

    if pid > 1 and os.path.exists(f"/proc/{pid}/io"):
        try:
            with open(f"/proc/{pid}/io", "r") as f:
                for line in f:
                    if line.startswith("read_bytes:") and rb == 0:
                        rb = int(line.split()[1])
                    elif line.startswith("write_bytes:") and wb == 0:
                        wb = int(line.split()[1])
                    elif line.startswith("rchar:"):
                        rc = int(line.split()[1])
                    elif line.startswith("wchar:"):
                        wc = int(line.split()[1])
        except Exception:
            pass

    return (rb + wb, rc + wc, rb, wb, rc, wc)


def read_window_cpu_time(pid, cgroups):
    """Returns total CPU time in seconds aggregated across window scopes."""
    total_sec = 0.0
    found_cg = False
    if cgroups:
        for cg in cgroups:
            cg_path = f"/sys/fs/cgroup{cg}"
            if os.path.exists(f"{cg_path}/cpu.stat"):
                try:
                    with open(f"{cg_path}/cpu.stat", "r") as f:
                        for line in f:
                            if line.startswith("usage_usec"):
                                total_sec += int(line.split()[1]) / 1_000_000.0
                                found_cg = True
                except Exception:
                    pass
    if not found_cg and pid > 1 and os.path.exists(f"/proc/{pid}/stat"):
        try:
            with open(f"/proc/{pid}/stat", "r") as f:
                content = f.read()
            rparen = content.rfind(")")
            if rparen != -1:
                fields = content[rparen + 2:].split()
                utime = int(fields[11])
                stime = int(fields[12])
                total_sec = (utime + stime) / 100.0
        except Exception:
            pass
    return total_sec


def fmt_bytes(b):
    if b >= 1024 * 1024 * 1024:
        return f"{b / (1024 * 1024 * 1024):.1f}G"
    elif b >= 1024 * 1024:
        return f"{b / (1024 * 1024):.1f}M"
    elif b >= 1024:
        return f"{b / 1024:.0f}K"
    return f"{b}B"


def fmt_rate(r):
    if r >= 1024 * 1024:
        return f"{r / (1024 * 1024):.1f}M/s"
    elif r >= 1024:
        return f"{r / 1024:.0f}K/s"
    elif r > 0:
        return f"{r:.0f}B/s"
    return "0B/s"


def render_gauge(pct, width=10):
    """Renders an ASCII/Unicode progress bar e.g. [██████░░░░]."""
    pct = max(0, min(100, pct))
    filled = int(round((pct / 100.0) * width))
    empty = width - filled
    return "█" * filled + "░" * empty


class MetricsTracker:
    def __init__(self):
        self.history = {}

    def update_and_get(self, pid, cgroups):
        curr_time = time.time()
        curr_cpu = read_window_cpu_time(pid, cgroups)
        curr_disk, curr_sys, rb, wb, rc, wc = read_window_io(pid, cgroups)

        prev = self.history.get(pid)

        # Rate smoothing: only recalculate rates if at least 0.4s has elapsed
        if prev and (curr_time - prev["time"] >= 0.4):
            dt = curr_time - prev["time"]
            cpu_delta = max(0.0, curr_cpu - prev["cpu_time"])
            cpu_pct = (cpu_delta / dt) * 100.0
            disk_rate = max(0.0, (curr_disk - prev["disk_bytes"]) / dt)
            sys_rate = max(0.0, (curr_sys - prev["sys_bytes"]) / dt)

            self.history[pid] = {
                "time": curr_time,
                "cpu_time": curr_cpu,
                "disk_bytes": curr_disk,
                "sys_bytes": curr_sys,
                "read_bytes": rb,
                "write_bytes": wb,
                "rchar": rc,
                "wchar": wc,
                "cached_cpu_pct": cpu_pct,
                "cached_disk_rate": disk_rate,
                "cached_sys_rate": sys_rate,
            }
        elif prev:
            cpu_pct = prev.get("cached_cpu_pct", 0.0)
            disk_rate = prev.get("cached_disk_rate", 0.0)
            sys_rate = prev.get("cached_sys_rate", 0.0)
        else:
            cpu_pct = 0.0
            disk_rate = 0.0
            sys_rate = 0.0
            self.history[pid] = {
                "time": curr_time,
                "cpu_time": curr_cpu,
                "disk_bytes": curr_disk,
                "sys_bytes": curr_sys,
                "read_bytes": rb,
                "write_bytes": wb,
                "rchar": rc,
                "wchar": wc,
                "cached_cpu_pct": cpu_pct,
                "cached_disk_rate": disk_rate,
                "cached_sys_rate": sys_rate,
            }

        return {
            "cpu_pct": cpu_pct,
            "cpu_time": curr_cpu,
            "disk_rate": disk_rate,
            "disk_total": curr_disk,
            "sys_rate": sys_rate,
            "sys_total": curr_sys,
            "read_bytes": rb,
            "write_bytes": wb,
            "rchar": rc,
            "wchar": wc,
        }


class ControlPanelApp:
    def __init__(self, stdscr):
        self.stdscr = stdscr
        curses.use_default_colors()
        curses.curs_set(0)
        self.stdscr.keypad(True)
        if hasattr(curses, "set_escdelay"):
            try:
                curses.set_escdelay(25)
            except Exception:
                pass

        ensure_cgroup_controllers()

        # Color pairs:
        curses.init_pair(1, curses.COLOR_WHITE, -1)  # Normal text
        curses.init_pair(2, curses.COLOR_CYAN, -1)  # Accent / cyan
        curses.init_pair(3, curses.COLOR_BLACK, curses.COLOR_CYAN)  # Selected / cursor row
        curses.init_pair(4, curses.COLOR_GREEN, -1)  # Active / success
        curses.init_pair(5, curses.COLOR_YELLOW, -1)  # Throttled / warning
        curses.init_pair(6, curses.COLOR_RED, -1)  # Frozen / danger
        curses.init_pair(7, curses.COLOR_BLUE, -1)  # Borders / muted
        curses.init_pair(8, curses.COLOR_MAGENTA, -1)  # Magenta badge
        curses.init_pair(9, curses.COLOR_BLACK, curses.COLOR_GREEN)  # Active tab

        # Tabs: 0 = Windows, 1 = Profiles
        self.tab = 0
        self.tab_names = ["1: Windows & Resources", "2: System Profiles"]

        self.cursor_idx = 0
        self.scroll_offset = 0
        self.selected_addrs = set()
        self.bulk_target = None

        self.sort_mode = "workspace"  # "workspace", "cpu", "mem", "state", "class"
        self.search_query = ""
        self.searching = False

        self.metrics = MetricsTracker()
        self.show_help = False
        self.show_mem_modal = False
        self.flash_msg = ""
        self.flash_time = 0
        self.last_poll_time = 0

        self.clients = []
        self.filtered_clients = []
        self.tree_items = []
        self.collapsed_lanes = set()
        self.collapsed_workspaces = set()
        self.collapsed_groups = set()
        self.active_addr = None
        self.initial_active_set = False

        # Background worker sync for zero-lag UI
        self.running = True
        self.data_lock = threading.Lock()
        self.last_input_time = 0.0
        self.pending_rebuild = False
        self._pending_clients = []
        self._pending_active_ws = ""
        self._pending_active_addr = None
        self.worker_thread = None

        # Profile execution index
        self.profile_cursor = 0
        self.profiles = [
            ("1", "🚀 Extreme Game / Focus Mode", "Freeze or idle background workspaces; max priority (weight 1000) for active game"),
            ("2", "💻 Dev & Compilation Mode", "Prioritize active editors/terminals (weight 500); cap background browsers to 25% CPU"),
            ("3", "🔋 Battery & Quiet Saver Mode", "Cap all non-active windows to 15% CPU quota and enable SCHED_IDLE to silence fans"),
            ("4", "❄ Freeze All Inactive Windows", "Suspend all background windows in RAM at 0% CPU without quitting applications"),
            ("5", "󰓅 Thaw All Windows", "Resume all paused and frozen windows back to full execution"),
            ("6", "󰁨 Restore Defaults Across System", "Clear all CPU/RAM limits, unfreeze, and restore standard CFS weights to 100"),
            ("7", "🧹 Global Memory Cache Reclaim", "Force kernel to reclaim inactive page cache across all application cgroups"),
        ]

    def set_flash(self, msg):
        self.flash_msg = msg
        self.flash_time = time.time()

    def _background_worker(self):
        """Asynchronous worker that fetches clients and stats without blocking UI navigation."""
        while self.running:
            time.sleep(1.2)
            if not self.running:
                break
            # Skip update if user is actively navigating/typing (< 0.8s) to ensure 0 stutter
            if time.time() - self.last_input_time < 0.8:
                continue

            try:
                raw_clients = get_hypr_clients()
                active_ws = get_hypr_active_workspace()
                active_addr = get_hypr_active_client(raw_clients)

                if not active_ws and active_addr:
                    for c in raw_clients:
                        if c.get("address") == active_addr:
                            active_ws = c.get("workspace", {}).get("name", "")
                            break

                for c in raw_clients:
                    info = read_cgroup_info_for_window(c)
                    c["_cgroups"] = info["cgroups"]
                    c["_info"] = info
                    m = self.metrics.update_and_get(c.get("pid", 0), info["cgroups"])
                    c["_metrics"] = m
                    c["_cpu_pct"] = m["cpu_pct"]
                    c["_mem_mb"] = info["mem_curr"]

                with self.data_lock:
                    self._pending_clients = raw_clients
                    self._pending_active_ws = active_ws
                    self._pending_active_addr = active_addr
                    self.pending_rebuild = True
            except Exception:
                pass

    def apply_search_and_build(self, active_ws=None, preserve_cursor=True):
        """Filters cached clients and rebuilds tree items in sub-millisecond time."""
        saved_target = None
        if preserve_cursor and self.tree_items and 0 <= self.cursor_idx < len(self.tree_items):
            item = self.tree_items[self.cursor_idx]
            i_type = item["type"]
            if i_type == "client":
                saved_target = ("client", item["client"].get("address"))
            elif i_type == "workspace":
                saved_target = ("workspace", item.get("ws_name"))
            elif i_type == "lane":
                saved_target = ("lane", item.get("lane_key"))
            elif i_type == "group":
                saved_target = ("group", item.get("group_id"))

        if self.search_query:
            q = self.search_query.lower()
            self.filtered_clients = [
                c
                for c in self.clients
                if q in str(c.get("class", "")).lower()
                or q in str(c.get("title", "")).lower()
                or q in str(c.get("workspace", {}).get("name", "")).lower()
                or q in str(c.get("pid", ""))
            ]
        else:
            self.filtered_clients = list(self.clients)

        self.build_tree_items(active_ws)

        restored = False
        if saved_target:
            t_type, t_id = saved_target
            for idx, item in enumerate(self.tree_items):
                if t_type == "client" and item["type"] == "client" and item["client"].get("address") == t_id:
                    self.cursor_idx = idx
                    restored = True
                    break
                elif t_type == "workspace" and item["type"] == "workspace" and item.get("ws_name") == t_id:
                    self.cursor_idx = idx
                    restored = True
                    break
                elif t_type == "lane" and item["type"] == "lane" and item.get("lane_key") == t_id:
                    self.cursor_idx = idx
                    restored = True
                    break
                elif t_type == "group" and item["type"] == "group" and item.get("group_id") == t_id:
                    self.cursor_idx = idx
                    restored = True
                    break

        if not restored:
            if not self.initial_active_set and self.active_addr:
                for idx, item in enumerate(self.tree_items):
                    if item["type"] == "client" and item["client"].get("address") == self.active_addr:
                        self.cursor_idx = idx
                        self.initial_active_set = True
                        restored = True
                        break
            if not restored:
                if self.tree_items:
                    self.cursor_idx = max(0, min(self.cursor_idx, len(self.tree_items) - 1))
                else:
                    self.cursor_idx = 0

    def update_clients(self, preserve_cursor=True):
        """Initial synchronous data load."""
        raw_clients = get_hypr_clients()
        self.active_addr = get_hypr_active_client(raw_clients)
        active_ws = get_hypr_active_workspace()

        if not active_ws and self.active_addr:
            for c in raw_clients:
                if c.get("address") == self.active_addr:
                    active_ws = c.get("workspace", {}).get("name", "")
                    break

        for c in raw_clients:
            info = read_cgroup_info_for_window(c)
            c["_cgroups"] = info["cgroups"]
            c["_info"] = info
            m = self.metrics.update_and_get(c.get("pid", 0), info["cgroups"])
            c["_metrics"] = m
            c["_cpu_pct"] = m["cpu_pct"]
            c["_mem_mb"] = info["mem_curr"]

        self.clients = raw_clients
        self.apply_search_and_build(active_ws=active_ws, preserve_cursor=preserve_cursor)

    def build_tree_items(self, active_ws=None):
        """Constructs interactive hierarchical tree items (lane -> workspace -> windows)."""
        items = []
        if not self.filtered_clients:
            self.tree_items = []
            return

        if self.sort_mode == "workspace":
            lanes = {}
            for c in self.filtered_clients:
                ws = c.get("workspace", {}).get("name", "1")
                lane_key, lane_label, ws_key, ws_label, ws_rank = parse_workspace_lane(ws)

                if lane_key not in lanes:
                    if lane_key == "NUMBERED":
                        l_rank = (1, "NUMBERED")
                    elif lane_key == "SPECIAL":
                        l_rank = (2, "SPECIAL")
                    else:
                        l_rank = (0, lane_key)

                    lanes[lane_key] = {
                        "lane_key": lane_key,
                        "lane_label": lane_label,
                        "lane_rank": l_rank,
                        "workspaces": {},
                    }

                ws_dict = lanes[lane_key]["workspaces"]
                if ws_key not in ws_dict:
                    ws_dict[ws_key] = {
                        "ws_key": ws_key,
                        "ws_label": ws_label,
                        "ws_rank": ws_rank,
                        "clients": [],
                    }
                ws_dict[ws_key]["clients"].append(c)

            sorted_lanes = sorted(lanes.values(), key=lambda l: l["lane_rank"])

            # Default to all collapsed except current active lane & active workspace on initial run
            if not self.initial_active_set and active_ws:
                active_lane_key, _, active_ws_key, _, _ = parse_workspace_lane(active_ws)
                for l_data in sorted_lanes:
                    lk = l_data["lane_key"]
                    if lk != active_lane_key:
                        self.collapsed_lanes.add(lk)
                    else:
                        self.collapsed_lanes.discard(lk)

                    for wk in l_data["workspaces"]:
                        if wk != active_ws_key:
                            self.collapsed_workspaces.add(wk)
                        else:
                            self.collapsed_workspaces.discard(wk)

            for l_data in sorted_lanes:
                lk = l_data["lane_key"]
                is_lane_collapsed = lk in self.collapsed_lanes

                sorted_ws_list = sorted(l_data["workspaces"].values(), key=lambda w: w["ws_rank"])
                lane_clients = []
                for w_data in sorted_ws_list:
                    lane_clients.extend(w_data["clients"])

                lane_mem = sum(c.get("_mem_mb", 0) for c in lane_clients)
                lane_cpu = sum(c.get("_cpu_pct", 0) for c in lane_clients)
                lane_frozen = sum(1 for c in lane_clients if c.get("_info", {}).get("freeze") == "1")
                lane_throt = sum(1 for c in lane_clients if c.get("_info", {}).get("cpu_max") != "max" or c.get("_info", {}).get("cpu_idle") == "1")
                lane_active = len(lane_clients) - lane_frozen

                lane_node = {
                    "type": "lane",
                    "lane_key": lk,
                    "label": l_data["lane_label"],
                    "clients": lane_clients,
                    "ws_count": len(sorted_ws_list),
                    "count": len(lane_clients),
                    "total_mem": lane_mem,
                    "total_cpu": lane_cpu,
                    "frozen_cnt": lane_frozen,
                    "throt_cnt": lane_throt,
                    "active_cnt": lane_active,
                    "collapsed": is_lane_collapsed,
                    "depth": 0,
                }
                items.append(lane_node)

                if not is_lane_collapsed:
                    for w_data in sorted_ws_list:
                        wk = w_data["ws_key"]
                        is_ws_collapsed = wk in self.collapsed_workspaces
                        ws_wins = w_data["clients"]
                        ws_wins.sort(key=lambda c: (c.get("focusHistoryID", 9999), c.get("class", "")))

                        ws_mem = sum(c.get("_mem_mb", 0) for c in ws_wins)
                        ws_cpu = sum(c.get("_cpu_pct", 0) for c in ws_wins)
                        ws_frozen = sum(1 for c in ws_wins if c.get("_info", {}).get("freeze") == "1")
                        ws_throt = sum(1 for c in ws_wins if c.get("_info", {}).get("cpu_max") != "max" or c.get("_info", {}).get("cpu_idle") == "1")
                        ws_active = len(ws_wins) - ws_frozen

                        ws_node = {
                            "type": "workspace",
                            "lane_key": lk,
                            "ws_name": wk,
                            "label": w_data["ws_label"],
                            "clients": ws_wins,
                            "count": len(ws_wins),
                            "total_mem": ws_mem,
                            "total_cpu": ws_cpu,
                            "frozen_cnt": ws_frozen,
                            "throt_cnt": ws_throt,
                            "active_cnt": ws_active,
                            "collapsed": is_ws_collapsed,
                            "depth": 1,
                        }
                        items.append(ws_node)

                        if not is_ws_collapsed:
                            for c_idx, c in enumerate(ws_wins):
                                is_last = c_idx == len(ws_wins) - 1
                                items.append({
                                    "type": "client",
                                    "client": c,
                                    "lane_key": lk,
                                    "ws_name": wk,
                                    "is_last": is_last,
                                    "depth": 2,
                                })

        elif self.sort_mode == "class":
            groups = {}
            for c in self.filtered_clients:
                cls = c.get("class") or "Unknown"
                ws = c.get("workspace", {}).get("name", "")
                if cls not in groups:
                    groups[cls] = {"key": f"cls:{cls.lower()}", "label": f"󰞌 APPLICATION [{cls}]", "clients": []}
                groups[cls]["clients"].append((c, ws))

            sorted_groups = sorted(groups.items(), key=lambda x: x[0].lower())
            for g_key, g_data in sorted_groups:
                clist_with_ws = g_data["clients"]
                raw_wins = [x[0] for x in clist_with_ws]
                tot_mem = sum(c.get("_mem_mb", 0) for c in raw_wins)
                tot_cpu = sum(c.get("_cpu_pct", 0) for c in raw_wins)
                frozen_cnt = sum(1 for c in raw_wins if c.get("_info", {}).get("freeze") == "1")
                throt_cnt = sum(1 for c in raw_wins if c.get("_info", {}).get("cpu_max") != "max")
                active_cnt = len(raw_wins) - frozen_cnt

                is_collapsed = g_data["key"] in self.collapsed_groups
                group_node = {
                    "type": "group",
                    "group_id": g_data["key"],
                    "label": g_data["label"],
                    "clients": raw_wins,
                    "count": len(raw_wins),
                    "total_mem": tot_mem,
                    "total_cpu": tot_cpu,
                    "frozen_cnt": frozen_cnt,
                    "throt_cnt": throt_cnt,
                    "active_cnt": active_cnt,
                    "collapsed": is_collapsed,
                    "depth": 0,
                }
                items.append(group_node)
                if not is_collapsed:
                    for c_idx, (c, sub_ws) in enumerate(clist_with_ws):
                        is_last = c_idx == len(clist_with_ws) - 1
                        items.append({
                            "type": "client",
                            "client": c,
                            "group_id": g_data["key"],
                            "ws_name": sub_ws,
                            "is_last": is_last,
                            "depth": 1,
                        })

        else:
            if self.sort_mode == "cpu":
                sorted_clients = sorted(self.filtered_clients, key=lambda c: c.get("_cpu_pct", 0), reverse=True)
                g1 = [c for c in sorted_clients if c.get("_cpu_pct", 0) >= 0.1]
                g2 = [c for c in sorted_clients if c.get("_cpu_pct", 0) < 0.1]
                section_defs = [
                    ("cpu:active", "🔥 ACTIVE CPU CONSUMERS (>= 0.1%)", g1),
                    ("cpu:idle", "💤 IDLE / BACKGROUND (0.0%)", g2),
                ]
            elif self.sort_mode == "mem":
                sorted_clients = sorted(self.filtered_clients, key=lambda c: c.get("_mem_mb", 0), reverse=True)
                g1 = [c for c in sorted_clients if c.get("_mem_mb", 0) >= 200]
                g2 = [c for c in sorted_clients if c.get("_mem_mb", 0) < 200]
                section_defs = [
                    ("mem:heavy", "󰍛 HIGH MEMORY (>= 200 MB)", g1),
                    ("mem:light", "󰍛 STANDARD MEMORY (< 200 MB)", g2),
                ]
            else:  # state
                sorted_clients = sorted(self.filtered_clients, key=lambda c: c.get("_info", {}).get("freeze", "0"), reverse=True)
                g1 = [c for c in sorted_clients if c.get("_info", {}).get("freeze") == "1"]
                g2 = [c for c in sorted_clients if c.get("_info", {}).get("cpu_max") != "max"]
                g3 = [c for c in sorted_clients if c not in g1 and c not in g2]
                section_defs = [
                    ("state:frozen", "❄ FROZEN APPLICATION WINDOWS", g1),
                    ("state:throt", "⚡ THROTTLED WINDOWS", g2),
                    ("state:normal", "● NORMAL ACTIVE WINDOWS", g3),
                ]

            for s_key, s_label, s_wins in section_defs:
                if not s_wins:
                    continue
                tot_mem = sum(c.get("_mem_mb", 0) for c in s_wins)
                tot_cpu = sum(c.get("_cpu_pct", 0) for c in s_wins)
                frozen_cnt = sum(1 for c in s_wins if c.get("_info", {}).get("freeze") == "1")
                throt_cnt = sum(1 for c in s_wins if c.get("_info", {}).get("cpu_max") != "max")
                active_cnt = len(s_wins) - frozen_cnt

                is_collapsed = s_key in self.collapsed_groups
                group_node = {
                    "type": "group",
                    "group_id": s_key,
                    "label": s_label,
                    "clients": s_wins,
                    "count": len(s_wins),
                    "total_mem": tot_mem,
                    "total_cpu": tot_cpu,
                    "frozen_cnt": frozen_cnt,
                    "throt_cnt": throt_cnt,
                    "active_cnt": active_cnt,
                    "collapsed": is_collapsed,
                    "depth": 0,
                }
                items.append(group_node)
                if not is_collapsed:
                    for c_idx, c in enumerate(s_wins):
                        is_last = c_idx == len(s_wins) - 1
                        sub_ws = c.get("workspace", {}).get("name", "")
                        items.append({
                            "type": "client",
                            "client": c,
                            "group_id": s_key,
                            "ws_name": sub_ws,
                            "is_last": is_last,
                            "depth": 1,
                        })

        self.tree_items = items

    def get_effective_targets(self):
        """Returns list of client dicts matching the current target selection."""
        if self.bulk_target:
            flag, val = self.bulk_target
            if flag == "--active":
                return [c for c in self.clients if c.get("address") == self.active_addr]
            elif flag == "--inactive":
                return [c for c in self.clients if c.get("address") != self.active_addr]
            elif flag == "--all":
                return list(self.clients)
            elif flag == "--workspace":
                return [c for c in self.clients if c.get("workspace", {}).get("name") == val]
            elif flag == "--anchor":
                prefix = val.upper()
                return [
                    c
                    for c in self.clients
                    if str(c.get("workspace", {}).get("name", "")).startswith(prefix + ":")
                    or c.get("workspace", {}).get("name") == prefix
                ]

        if self.selected_addrs:
            return [c for c in self.clients if c.get("address") in self.selected_addrs]

        if self.tree_items and 0 <= self.cursor_idx < len(self.tree_items):
            cur = self.tree_items[self.cursor_idx]
            if cur["type"] == "client":
                return [cur["client"]]
            elif cur["type"] in ("workspace", "lane", "group"):
                return list(cur.get("clients", []))

        return []

    def get_target_description(self):
        if self.bulk_target:
            flag, val = self.bulk_target
            if flag == "--active":
                return "Active Focused Window"
            elif flag == "--inactive":
                return "All Inactive Windows"
            elif flag == "--all":
                return "All System Windows"
            elif flag == "--workspace":
                return f"Workspace {val}"
            elif flag == "--anchor":
                return f"Anchor Lane {val}"
            return f"{flag} {val or ''}".strip()

        if self.selected_addrs:
            count = len(self.selected_addrs)
            names = [
                c.get("class") or "window"
                for c in self.clients
                if c.get("address") in self.selected_addrs
            ]
            names_str = ", ".join(names[:2]) + (f" +{count-2}" if count > 2 else "")
            return f"{count} Selected ({names_str})"

        if self.tree_items and 0 <= self.cursor_idx < len(self.tree_items):
            cur = self.tree_items[self.cursor_idx]
            if cur["type"] == "client":
                c = cur["client"]
                cclass = c.get("class") or "window"
                pid = c.get("pid", 0)
                is_active = c.get("address") == self.active_addr
                act_tag = " [Active]" if is_active else ""
                return f"[{cclass}] PID {pid}{act_tag}"
            elif cur["type"] == "workspace":
                return f"Workspace {cur['ws_name']} ({cur['count']} wins)"
            elif cur["type"] == "lane":
                return f"Anchor Lane {cur['lane_key']} ({cur['count']} wins)"
            elif cur["type"] == "group":
                return f"{cur['label']} ({cur['count']} wins)"

        return "No Target Selected"

    def execute_knob_on_targets(self, knob, value):
        targets = self.get_effective_targets()
        if not targets:
            self.set_flash("⚠ No targets selected.")
            return

        applied = 0
        desc = self.get_target_description()
        for c in targets:
            ok, _ = apply_knob_to_window(c, knob, value)
            if ok:
                applied += 1
                info = c.get("_info") or {}
                if knob == "cpu.max":
                    info["cpu_max"] = value
                    quota = value.split()[0]
                    if quota.isdigit():
                        info["cpu_max_pct"] = min(100, max(1, int(quota) // 1000))
                    elif quota == "max":
                        info["cpu_max_pct"] = 100
                elif knob == "cpu.weight":
                    info["cpu_weight"] = value
                elif knob == "memory.high":
                    info["mem_high"] = value
                    info["mem_high_disp"] = fmt_mem_val(value)
                elif knob == "memory.max":
                    info["mem_max"] = value
                    info["mem_max_disp"] = fmt_mem_val(value)
                elif knob == "cgroup.freeze":
                    info["freeze"] = value
                c["_info"] = info

        self.set_flash(f"✓ Applied {knob}={value} ({applied} window(s))")
        notify(f"Control Panel: {knob}", f"{value} -> {desc}")
        self.bulk_target = None

    def adjust_cpu_quota_targets(self, delta_pct):
        targets = self.get_effective_targets()
        if not targets:
            self.set_flash("⚠ No targets selected.")
            return

        for c in targets:
            info = c.get("_info") or read_cgroup_info_for_window(c)
            curr = info.get("cpu_max_pct", 100)
            if info.get("cpu_max") == "max":
                curr = 100
            new_pct = max(5, min(100, curr + delta_pct))
            val = "max 100000" if new_pct >= 100 else f"{new_pct * 1000} 100000"
            ok, _ = apply_knob_to_window(c, "cpu.max", val)
            if ok:
                info["cpu_max_pct"] = new_pct
                info["cpu_max"] = val
                c["_info"] = info

        desc = self.get_target_description()
        self.set_flash(f"✓ Adjusted CPU quota for {desc} (±{delta_pct}%)")

    def adjust_cpu_weight_targets(self, delta_weight):
        targets = self.get_effective_targets()
        if not targets:
            self.set_flash("⚠ No targets selected.")
            return

        for c in targets:
            info = c.get("_info") or read_cgroup_info_for_window(c)
            try:
                curr = int(info.get("cpu_weight", "100"))
            except Exception:
                curr = 100
            new_wt = max(10, min(1000, curr + delta_weight))
            ok, _ = apply_knob_to_window(c, "cpu.weight", str(new_wt))
            if ok:
                info["cpu_weight"] = str(new_wt)
                c["_info"] = info

        desc = self.get_target_description()
        self.set_flash(f"✓ Adjusted CPU weight for {desc} ({delta_weight:+d})")

    def toggle_freeze_targets(self):
        targets = self.get_effective_targets()
        if not targets:
            self.set_flash("⚠ No targets selected.")
            return

        any_frozen = False
        for c in targets:
            info = c.get("_info") or read_cgroup_info_for_window(c)
            if info.get("freeze") == "1":
                any_frozen = True
                break

        new_state = "0" if any_frozen else "1"
        action_name = "Thawed" if any_frozen else "Frozen"
        for c in targets:
            apply_knob_to_window(c, "cgroup.freeze", new_state)
            info = c.get("_info") or {}
            info["freeze"] = new_state
            c["_info"] = info

        desc = self.get_target_description()
        self.set_flash(f"✓ {action_name} {desc}")
        notify(
            f"Control Panel: {action_name}",
            f"{desc} suspended in RAM" if not any_frozen else f"{desc} resumed to active",
        )
        self.bulk_target = None

    def reset_selected_targets(self):
        targets = self.get_effective_targets()
        if not targets:
            self.set_flash("⚠ No targets selected.")
            return

        desc = self.get_target_description()
        for c in targets:
            reset_window_limits(c)
            info = c.get("_info") or {}
            info["cpu_max"] = "max"
            info["cpu_max_pct"] = 100
            info["cpu_weight"] = "100"
            info["cpu_idle"] = "0"
            info["freeze"] = "0"
            info["mem_high"] = "max"
            info["mem_high_disp"] = "max"
            info["mem_max"] = "max"
            info["mem_max_disp"] = "max"
            c["_info"] = info

        self.set_flash(f"✓ Restored defaults for {desc}")
        notify("Control Panel: Reset", f"Limits cleared for {desc}")
        self.bulk_target = None

    def reset_all_system(self):
        confirm = self.prompt_string("Reset ALL limits & unfreeze system-wide? [y/N]")
        if confirm.lower() in ("y", "yes"):
            for c in self.clients:
                reset_window_limits(c)
                info = c.get("_info") or {}
                info["cpu_max"] = "max"
                info["cpu_max_pct"] = 100
                info["cpu_weight"] = "100"
                info["cpu_idle"] = "0"
                info["freeze"] = "0"
                info["mem_high"] = "max"
                info["mem_high_disp"] = "max"
                info["mem_max"] = "max"
                info["mem_max_disp"] = "max"
                c["_info"] = info
            self.set_flash("✓ All limits restored to defaults across entire system.")
            notify("Control Panel: Reset All", "Restored defaults across all windows.")
        else:
            self.set_flash("System reset cancelled.")

    def toggle_collapse_all(self):
        """Toggles collapsing all workspace groups/lanes or expanding all."""
        if self.sort_mode == "workspace":
            all_lane_keys = [item["lane_key"] for item in self.tree_items if item["type"] == "lane"]
            all_ws_keys = [item["ws_name"] for item in self.tree_items if item["type"] == "workspace"]
            any_collapsed = bool(self.collapsed_lanes or self.collapsed_workspaces)
            if any_collapsed:
                self.collapsed_lanes.clear()
                self.collapsed_workspaces.clear()
                self.set_flash("Expanded all lanes & workspaces")
            else:
                cur_lane = None
                cur_ws = None
                if 0 <= self.cursor_idx < len(self.tree_items):
                    cur = self.tree_items[self.cursor_idx]
                    cur_lane = cur.get("lane_key")
                    cur_ws = cur.get("ws_name")
                for lk in all_lane_keys:
                    if lk != cur_lane:
                        self.collapsed_lanes.add(lk)
                for wk in all_ws_keys:
                    if wk != cur_ws:
                        self.collapsed_workspaces.add(wk)
                self.set_flash("Collapsed all lanes & workspaces except active")
            self.build_tree_items()
            return

        all_group_ids = [item["group_id"] for item in self.tree_items if item["type"] == "group"]
        if not all_group_ids:
            return

        any_collapsed = any(gid in self.collapsed_groups for gid in all_group_ids)
        if any_collapsed:
            self.collapsed_groups.clear()
            self.set_flash("Expanded all groups")
        else:
            cur_gid = None
            if 0 <= self.cursor_idx < len(self.tree_items):
                cur_gid = self.tree_items[self.cursor_idx].get("group_id")
            for gid in all_group_ids:
                if gid != cur_gid:
                    self.collapsed_groups.add(gid)
            self.set_flash("Collapsed all groups")
        self.build_tree_items()

    def render_mem_modal(self):
        h, w = self.stdscr.getmaxyx()
        modal_w = min(w - 6, 86)
        modal_h = min(h - 4, 25)
        top = max(1, (h - modal_h) // 2)
        left = max(2, (w - modal_w) // 2)

        desc = self.get_target_description()
        targets = self.get_effective_targets()

        try:
            self.stdscr.addstr(top, left, f"╭─ 󰘚 CGROUP MEMORY CONTROLS: {desc[:modal_w-32]} " + "─" * max(0, modal_w - len(desc) - 32) + "╮", curses.color_pair(2) | curses.A_BOLD)
            for r in range(top + 1, top + modal_h - 1):
                self.stdscr.addstr(r, left, "│" + " " * (modal_w - 2) + "│", curses.color_pair(7))
            self.stdscr.addstr(top + modal_h - 1, left, "╰" + "─" * (modal_w - 30) + " Press [M/Esc/q] to close ─╯", curses.color_pair(2))
        except curses.error:
            pass

        r = top + 1
        x = left + 3
        inner_w = modal_w - 6

        if targets:
            tot_curr = sum(c.get("_mem_mb", 0) for c in targets)
            tot_peak = sum(c.get("_info", {}).get("mem_peak", c.get("_mem_mb", 0)) for c in targets)
            high_disp = targets[0].get("_info", {}).get("mem_high_disp", "max") if len(targets) == 1 else "multi"
            max_disp = targets[0].get("_info", {}).get("mem_max_disp", "max") if len(targets) == 1 else "multi"
            stat_line = f"Target: {desc} ({len(targets)} wins)  |  RAM: {tot_curr} MB  |  Peak: {tot_peak} MB"
            lim_line = f"memory.high (soft throttle): {high_disp}  |  memory.max (hard OOM): {max_disp}"
        else:
            stat_line = "No target selected."
            lim_line = ""

        try:
            self.stdscr.addstr(r, x, stat_line[:inner_w], curses.color_pair(1) | curses.A_BOLD)
            r += 1
            if lim_line:
                self.stdscr.addstr(r, x, lim_line[:inner_w], curses.color_pair(8))
                r += 1
            self.stdscr.addstr(r, left, "├" + "─" * (modal_w - 2) + "┤", curses.color_pair(7))
            r += 1

            self.stdscr.addstr(r, x, "▶ SOFT LIMITS (memory.high - throttles & triggers proactive reclaim):", curses.color_pair(2) | curses.A_BOLD)
            r += 1
            soft_presets = [
                ("[1]", "250 MB"),
                ("[2]", "500 MB"),
                ("[3]", "1.0 GB"),
                ("[4]", "2.0 GB"),
                ("[5]", "4.0 GB"),
                ("[8]", "Custom..."),
            ]
            px = x + 2
            for key_h, val_h in soft_presets:
                self.stdscr.addstr(r, px, f"{key_h} {val_h}", curses.color_pair(1))
                px += 13
            r += 2

            self.stdscr.addstr(r, left, "├" + "─" * (modal_w - 2) + "┤", curses.color_pair(7))
            r += 1

            self.stdscr.addstr(r, x, "▶ HARD CEILINGS (memory.max - strict cap, triggers OOM if exceeded):", curses.color_pair(5) | curses.A_BOLD)
            r += 1
            hard_presets = [
                ("[6]", "1.0 GB"),
                ("[7]", "2.0 GB"),
                ("[9]", "Custom Value..."),
            ]
            px = x + 2
            for key_h, val_h in hard_presets:
                self.stdscr.addstr(r, px, f"{key_h} {val_h}", curses.color_pair(1))
                px += 18
            r += 2

            self.stdscr.addstr(r, left, "├" + "─" * (modal_w - 2) + "┤", curses.color_pair(7))
            r += 1

            self.stdscr.addstr(r, x, "▶ RECLAIM & RESTORE:", curses.color_pair(4) | curses.A_BOLD)
            r += 1
            self.stdscr.addstr(r, x + 2, "[c] Force Page Cache Reclaim (250MB)", curses.color_pair(1) | curses.A_BOLD)
            self.stdscr.addstr(r, x + 44, "[0] Clear Memory Limits (set 'max')", curses.color_pair(4) | curses.A_BOLD)
            r += 1
        except curses.error:
            pass

    def execute_profile(self, idx):
        if idx == 0:  # Game / Extreme Focus Mode
            active_ws = ""
            for c in self.clients:
                if c.get("address") == self.active_addr:
                    active_ws = c.get("workspace", {}).get("name", "")
                    apply_knob_to_window(c, "cgroup.freeze", "0")
                    apply_knob_to_window(c, "cpu.weight", "1000")
                    apply_knob_to_window(c, "cpu.max", "max 100000")

            count = 0
            for c in self.clients:
                if c.get("workspace", {}).get("name") != active_ws and c.get("address") != self.active_addr:
                    apply_knob_to_window(c, "cgroup.freeze", "1")
                    count += 1
            self.set_flash(f"✓ Game Mode Enabled: Suspended {count} background window(s)")
            notify("Control Panel: Game Mode", f"Suspended {count} background window(s) to guarantee 100% CPU/GPU focus.")

        elif idx == 1:  # Dev & Compilation Mode
            for c in self.clients:
                cclass = str(c.get("class", "")).lower()
                if c.get("address") == self.active_addr or "kitty" in cclass or "nvim" in cclass:
                    apply_knob_to_window(c, "cpu.weight", "500")
                    apply_knob_to_window(c, "cpu.max", "max 100000")
                elif "firefox" in cclass or "chromium" in cclass or "vivaldi" in cclass:
                    apply_knob_to_window(c, "cpu.max", "25000 100000")
                    apply_knob_to_window(c, "cpu.weight", "50")
            self.set_flash("✓ Dev Profile: Prioritized terminals/editors; throttled background browsers")
            notify("Control Panel: Dev Mode", "Prioritized development tools and throttled browser tabs.")

        elif idx == 2:  # Battery / Quiet Saver Mode
            for c in self.clients:
                if c.get("address") != self.active_addr:
                    apply_knob_to_window(c, "cpu.max", "15000 100000")
                    apply_knob_to_window(c, "cpu.idle", "1")
            self.set_flash("✓ Battery Saver: 15% quota + SCHED_IDLE on all background windows")
            notify("Control Panel: Battery Saver", "Throttled background windows to reduce power and fan noise.")

        elif idx == 3:  # Freeze Inactive
            count = 0
            for c in self.clients:
                if c.get("address") != self.active_addr:
                    apply_knob_to_window(c, "cgroup.freeze", "1")
                    count += 1
            self.set_flash(f"✓ Suspended {count} background window(s)")
            notify("Control Panel: Freeze Inactive", f"Suspended {count} background window(s) in RAM.")

        elif idx == 4:  # Thaw All
            for c in self.clients:
                apply_knob_to_window(c, "cgroup.freeze", "0")
            self.set_flash("✓ Thawed all windows across the system")
            notify("Control Panel: Thaw All", "Resumed all suspended windows.")

        elif idx == 5:  # Restore All Defaults
            for c in self.clients:
                reset_window_limits(c)
            self.set_flash("✓ Restored all limits to system defaults")
            notify("Control Panel: Reset All", "Removed all quotas and restored default weights.")

        elif idx == 6:  # Global Memory Cache Reclaim
            reclaimed = 0
            for c in self.clients:
                ok, _ = apply_knob_to_window(c, "memory.reclaim", "100M")
                if ok:
                    reclaimed += 1
            self.set_flash(f"✓ Reclaimed page cache across {reclaimed} window scope(s)")
            notify("Control Panel: Memory Reclaim", f"Reclaimed kernel page cache on {reclaimed} scopes.")

    def prompt_string(self, prompt_text):
        h, w = self.stdscr.getmaxyx()
        prompt_x = 2
        prompt_y = max(1, h - 3)
        avail = max(10, w - prompt_x - 4)
        disp_prompt = prompt_text[:avail] + ": "

        self.stdscr.timeout(-1)  # Fully blocking mode: user has infinite time to type
        curses.curs_set(1)

        buffer = []
        try:
            while True:
                self.stdscr.move(prompt_y, prompt_x)
                self.stdscr.clrtoeol()
                self.stdscr.addstr(prompt_y, prompt_x, disp_prompt, curses.color_pair(2) | curses.A_BOLD)
                curr_txt = "".join(buffer)
                input_x = prompt_x + len(disp_prompt)
                max_w = max(1, w - input_x - 2)
                self.stdscr.addstr(prompt_y, input_x, curr_txt[-max_w:], curses.color_pair(1) | curses.A_BOLD)
                self.stdscr.refresh()

                ch = self.stdscr.getch()
                if ch in (10, 13, curses.KEY_ENTER):
                    break
                elif ch in (27,):  # Esc cancels prompt
                    buffer = []
                    break
                elif ch in (curses.KEY_BACKSPACE, 127, 8, ord("\b")):
                    if buffer:
                        buffer.pop()
                elif 32 <= ch <= 126:
                    if len(buffer) < 45:
                        buffer.append(chr(ch))
        finally:
            curses.curs_set(0)
            self.stdscr.timeout(40)  # restore fast responsive UI loop
            self.last_input_time = time.time()

        return "".join(buffer).strip()

    def draw_banner(self):
        h, w = self.stdscr.getmaxyx()
        try:
            # Row 1: App Title (Left) + Target Info (Right)
            self.stdscr.addstr(1, 2, "󰘚 HYPRLAND CONTROL PANEL", curses.color_pair(2) | curses.A_BOLD)
            target_str = f" Target: {self.get_target_description()} "
            if len(target_str) + 30 < w:
                self.stdscr.addstr(1, max(30, w - len(target_str) - 2), target_str, curses.color_pair(8) | curses.A_BOLD)

            # Row 2: Prominent Tab Switcher
            tab_x = 2
            for idx, name in enumerate(self.tab_names):
                is_active = idx == self.tab
                style = curses.color_pair(9) | curses.A_BOLD if is_active else curses.color_pair(1)
                txt = f" {name} "
                if tab_x + len(txt) < w - 16:
                    self.stdscr.addstr(2, tab_x, txt, style)
                    tab_x += len(txt) + 1

            sort_str = f"Sort: {self.sort_mode.capitalize()} [s]"
            if w - len(sort_str) - 2 > tab_x:
                self.stdscr.addstr(2, w - len(sort_str) - 2, sort_str, curses.color_pair(7))

            # Row 3: Horizontal line divider
            self.stdscr.addstr(3, 2, "─" * max(0, w - 4), curses.color_pair(7))
        except curses.error:
            pass

    def draw_footer(self, hints):
        h, w = self.stdscr.getmaxyx()
        try:
            if self.flash_msg and (time.time() - self.flash_time < 4.0):
                self.stdscr.addstr(h - 3, 2, f" {self.flash_msg[: w - 6]} ", curses.color_pair(4) | curses.A_BOLD)
            else:
                self.stdscr.addstr(h - 3, 2, "─" * max(0, w - 4), curses.color_pair(7))

            self.stdscr.addstr(h - 2, 2, hints[: w - 4], curses.color_pair(1))
        except curses.error:
            pass

    def render_tab_windows(self):
        h, w = self.stdscr.getmaxyx()
        split_mode = w >= 78
        left_w = int(w * 0.56) if split_mode else (w - 4)
        right_w = (w - left_w - 5) if split_mode else 0

        # Left Pane Table Header
        if split_mode:
            hdr = f"  {'HIERARCHY / WS':<14} {'SEL':<4}{'★':<2} {'CLASS':<10} {'STATE':<9} {'CPU':<6} {'MEM':<5} {'TITLE'}"
        else:
            hdr = f"  {'HIERARCHY / WS':<14} {'SEL':<4}{'★':<2} {'CLASS':<11} {'STATE':<10} {'CPU':<7} {'MEM':<7} {'LIMIT':<7} {'TITLE'}"

        try:
            self.stdscr.addstr(4, 2, hdr[: left_w - 2], curses.color_pair(2) | curses.A_BOLD)
            self.stdscr.addstr(5, 2, "─" * max(0, left_w - 2), curses.color_pair(7))
        except curses.error:
            pass

        max_rows = max(1, h - 9)
        total_items = len(self.tree_items)
        if self.cursor_idx < 0:
            self.cursor_idx = 0
        if total_items and self.cursor_idx >= total_items:
            self.cursor_idx = total_items - 1

        if self.cursor_idx < self.scroll_offset:
            self.scroll_offset = self.cursor_idx
        elif self.cursor_idx >= self.scroll_offset + max_rows:
            self.scroll_offset = self.cursor_idx - max_rows + 1

        visible = self.tree_items[self.scroll_offset : self.scroll_offset + max_rows]
        row = 6

        for idx_offset, item in enumerate(visible):
            actual_idx = self.scroll_offset + idx_offset
            is_cursor = actual_idx == self.cursor_idx
            arrow = "› " if is_cursor else "  "
            cursor_color = curses.color_pair(2) | curses.A_BOLD if is_cursor else curses.color_pair(7)

            if item["type"] == "lane":
                is_collapsed = item.get("collapsed", False)
                fold_icon = "▸" if is_collapsed else "▾"
                label = item["label"]
                count = item["count"]
                ws_cnt = item.get("ws_count", 0)
                mem_str = f"{item['total_mem']}M"
                cpu_str = f"{item['total_cpu']:.1f}%"
                collapsed_tag = " [COLLAPSED]" if is_collapsed else ""

                grp_addrs = [c.get("address") for c in item["clients"] if c.get("address")]
                sel_count = sum(1 for a in grp_addrs if a in self.selected_addrs)
                if sel_count == len(grp_addrs) and len(grp_addrs) > 0:
                    grp_sel = "[✓]"
                elif sel_count > 0:
                    grp_sel = "[~]"
                else:
                    grp_sel = "[ ]"

                line_txt = f"{grp_sel} {fold_icon} {label} ({ws_cnt} ws · {count} win · {mem_str} · {cpu_str}){collapsed_tag}"
                try:
                    self.stdscr.addstr(row, 2, arrow, cursor_color)
                    if is_cursor:
                        self.stdscr.addstr(row, 4, line_txt[: left_w - 4], curses.color_pair(3) | curses.A_BOLD)
                    else:
                        self.stdscr.addstr(row, 4, grp_sel, curses.color_pair(4) | curses.A_BOLD if sel_count else curses.color_pair(7))
                        self.stdscr.addstr(row, 8, f"{fold_icon} ", curses.color_pair(2) | curses.A_BOLD)
                        self.stdscr.addstr(row, 10, f"{label} ", curses.color_pair(2) | curses.A_BOLD)
                        avail_right = max(0, left_w - (11 + len(label)))
                        self.stdscr.addstr(row, 10 + len(label) + 1, f"({ws_cnt} ws · {count} win · {mem_str} · {cpu_str}){collapsed_tag}"[:avail_right], curses.color_pair(7))
                except curses.error:
                    pass

            elif item["type"] == "workspace":
                is_collapsed = item.get("collapsed", False)
                fold_icon = "▸" if is_collapsed else "▾"
                label = item["label"]
                count = item["count"]
                mem_str = f"{item['total_mem']}M"
                cpu_str = f"{item['total_cpu']:.1f}%"
                collapsed_tag = " [COLLAPSED]" if is_collapsed else ""

                grp_addrs = [c.get("address") for c in item["clients"] if c.get("address")]
                sel_count = sum(1 for a in grp_addrs if a in self.selected_addrs)
                if sel_count == len(grp_addrs) and len(grp_addrs) > 0:
                    grp_sel = "[✓]"
                elif sel_count > 0:
                    grp_sel = "[~]"
                else:
                    grp_sel = "[ ]"

                line_txt = f"  {grp_sel} {fold_icon} {label} ({count} win · {mem_str} · {cpu_str}){collapsed_tag}"
                try:
                    self.stdscr.addstr(row, 2, arrow, cursor_color)
                    if is_cursor:
                        self.stdscr.addstr(row, 4, line_txt[: left_w - 4], curses.color_pair(3) | curses.A_BOLD)
                    else:
                        self.stdscr.addstr(row, 6, grp_sel, curses.color_pair(4) | curses.A_BOLD if sel_count else curses.color_pair(7))
                        self.stdscr.addstr(row, 10, f"{fold_icon} ", curses.color_pair(8) | curses.A_BOLD)
                        self.stdscr.addstr(row, 12, f"{label} ", curses.color_pair(8) | curses.A_BOLD)
                        avail_right = max(0, left_w - (13 + len(label)))
                        self.stdscr.addstr(row, 12 + len(label) + 1, f"({count} win · {mem_str} · {cpu_str}){collapsed_tag}"[:avail_right], curses.color_pair(7))
                except curses.error:
                    pass

            elif item["type"] == "group":
                is_collapsed = item.get("collapsed", False)
                fold_icon = "▸" if is_collapsed else "▾"
                label = item["label"]
                count = item["count"]
                mem_str = f"{item['total_mem']}M"
                cpu_str = f"{item['total_cpu']:.1f}%"
                collapsed_tag = " [COLLAPSED]" if is_collapsed else ""

                grp_addrs = [c.get("address") for c in item["clients"] if c.get("address")]
                sel_count = sum(1 for a in grp_addrs if a in self.selected_addrs)
                if sel_count == len(grp_addrs) and len(grp_addrs) > 0:
                    grp_sel = "[✓]"
                elif sel_count > 0:
                    grp_sel = "[~]"
                else:
                    grp_sel = "[ ]"

                line_txt = f"{grp_sel} {fold_icon} {label} ({count} win · {mem_str} · {cpu_str}){collapsed_tag}"
                try:
                    self.stdscr.addstr(row, 2, arrow, cursor_color)
                    if is_cursor:
                        self.stdscr.addstr(row, 4, line_txt[: left_w - 4], curses.color_pair(3) | curses.A_BOLD)
                    else:
                        self.stdscr.addstr(row, 4, grp_sel, curses.color_pair(4) | curses.A_BOLD if sel_count else curses.color_pair(7))
                        self.stdscr.addstr(row, 8, f"{fold_icon} ", curses.color_pair(2) | curses.A_BOLD)
                        self.stdscr.addstr(row, 10, f"{label} ", curses.color_pair(2) | curses.A_BOLD)
                        avail_right = max(0, left_w - (11 + len(label)))
                        self.stdscr.addstr(row, 10 + len(label) + 1, f"({count} win · {mem_str} · {cpu_str}){collapsed_tag}"[:avail_right], curses.color_pair(7))
                except curses.error:
                    pass

            elif item["type"] == "client":
                c = item["client"]
                addr = c.get("address", "")
                pid = c.get("pid", 0)
                cclass = (c.get("class") or "unknown")[:10]
                ws_name = item.get("ws_name", "")
                if ws_name.startswith("special:"):
                    ws_disp = ws_name[8:][:5]
                else:
                    ws_disp = ws_name[:5]

                title = c.get("title") or ""
                is_active = addr == self.active_addr

                cg_info = c.get("_info") or {}
                metrics_data = c.get("_metrics") or {"cpu_pct": 0.0}

                is_selected = addr in self.selected_addrs
                is_frozen = cg_info.get("freeze") == "1"
                cpu_max_raw = cg_info.get("cpu_max", "max").replace(" 100000", "")
                is_throttled = cpu_max_raw != "max" or cg_info.get("cpu_idle") == "1"

                if is_frozen:
                    state_str = "❄ FROZEN"
                    state_color = curses.color_pair(6) | curses.A_BOLD
                elif is_throttled:
                    if cpu_max_raw.isdigit():
                        pct = int(cpu_max_raw) // 1000
                        state_str = f"⚡ {pct}%"
                    else:
                        state_str = "⚡ THROT"
                    state_color = curses.color_pair(5) | curses.A_BOLD
                elif cg_info.get("cpu_idle") == "1":
                    state_str = "💤 IDLE"
                    state_color = curses.color_pair(7)
                else:
                    state_str = "● Active"
                    state_color = curses.color_pair(4)

                cpu_pct = metrics_data.get("cpu_pct", 0.0)
                cpu_str = f"{cpu_pct:4.1f}%" if cpu_pct > 0.05 else " 0.0%"
                mem_str = f"{cg_info.get('mem_curr', 0)}M"

                sel_box = "[✓]" if is_selected else "[ ]"
                act_box = "★" if is_active else " "
                branch = "└──" if item.get("is_last") else "├──"

                depth_pad = "    " if item.get("depth", 1) >= 2 else "  "
                fixed_len = 54 if split_mode else 60
                avail_title = max(0, left_w - fixed_len - 3)
                title_disp = title[:avail_title]

                try:
                    self.stdscr.addstr(row, 2, arrow, cursor_color)
                    if is_cursor:
                        full_line = f"{depth_pad}{branch} {sel_box} {act_box:<2} {cclass:<10} {state_str:<9} {cpu_str:<6} {mem_str:<5} {title_disp}"
                        self.stdscr.addstr(row, 4, full_line[: left_w - 4], curses.color_pair(3))
                    else:
                        self.stdscr.addstr(row, 4, depth_pad + branch, curses.color_pair(7))
                        col_x = 4 + len(depth_pad) + len(branch) + 1
                        self.stdscr.addstr(row, col_x, sel_box, curses.color_pair(4) | curses.A_BOLD if is_selected else curses.color_pair(7))
                        col_x += 4
                        self.stdscr.addstr(row, col_x, act_box, curses.color_pair(5) | curses.A_BOLD if is_active else curses.color_pair(1))
                        col_x += 2
                        self.stdscr.addstr(row, col_x, f"{cclass:<10}", curses.color_pair(1) | curses.A_BOLD)
                        col_x += 11
                        self.stdscr.addstr(row, col_x, f"{state_str:<9}", state_color)
                        col_x += 10
                        self.stdscr.addstr(row, col_x, f"{cpu_str:<6}", curses.color_pair(2))
                        col_x += 7
                        self.stdscr.addstr(row, col_x, f"{mem_str:<5}", curses.color_pair(4))
                        col_x += 6
                        self.stdscr.addstr(row, col_x, title_disp[: max(0, left_w - col_x)], curses.color_pair(1))
                except curses.error:
                    pass

            row += 1

        if not self.tree_items:
            try:
                msg = "No windows matched query." if self.search_query else "No Hyprland windows detected."
                self.stdscr.addstr(6, 4, msg, curses.color_pair(7))
            except curses.error:
                pass

        # Right Pane Live Inspector
        if split_mode and right_w >= 30:
            rx = left_w + 3
            ry = 4
            if self.tree_items and 0 <= self.cursor_idx < len(self.tree_items):
                cur_item = self.tree_items[self.cursor_idx]
                if cur_item["type"] == "client":
                    self.render_inspector_client(cur_item["client"], rx, ry, right_w, h)
                elif cur_item["type"] == "workspace":
                    self.render_inspector_workspace(cur_item, rx, ry, right_w, h)
                elif cur_item["type"] == "lane":
                    self.render_inspector_lane(cur_item, rx, ry, right_w, h)
                elif cur_item["type"] == "group":
                    self.render_inspector_group(cur_item, rx, ry, right_w, h)

        footer = "[Tab] Profiles  [v/Space] Pick  [Enter/z] Fold  [Z] Fold All  [f] Freeze  [(/)] Weight  [1-4] Quota  [M] Memory  [0] Reset  [s] Sort  [/] Find  [h] Help  [Esc/q] Quit"
        self.draw_footer(footer)

    def render_inspector_lane(self, lane_item, rx, ry, right_w, h):
        label = lane_item["label"]
        wins = lane_item["clients"]
        lane_key = lane_item["lane_key"]
        total_mem = lane_item["total_mem"]
        total_cpu = lane_item["total_cpu"]
        count = lane_item["count"]
        ws_count = lane_item.get("ws_count", 1)
        active_cnt = lane_item["active_cnt"]
        frozen_cnt = lane_item["frozen_cnt"]
        throt_cnt = lane_item["throt_cnt"]

        try:
            self.stdscr.addstr(ry, rx, f"╭─ {label[:right_w-6]} " + "─" * max(0, right_w - len(label) - 6) + "╮", curses.color_pair(2) | curses.A_BOLD)
            for r in range(ry + 1, h - 3):
                self.stdscr.addstr(r, rx, "│" + " " * (right_w - 2) + "│", curses.color_pair(7))
            self.stdscr.addstr(h - 4, rx, "╰" + "─" * (right_w - 2) + "╯", curses.color_pair(7))
        except curses.error:
            pass

        ir = ry + 1
        ix = rx + 2
        iw = right_w - 4

        try:
            self.stdscr.addstr(ir, ix, f"LANE SUMMARY: {ws_count} WS · {count} Win(s)", curses.color_pair(1) | curses.A_BOLD)
            ir += 1
            status_parts = []
            if active_cnt: status_parts.append(f"● {active_cnt} active")
            if frozen_cnt: status_parts.append(f"❄ {frozen_cnt} frozen")
            if throt_cnt: status_parts.append(f"⚡ {throt_cnt} throttled")
            status_text = "  ".join(status_parts) or "All normal"
            self.stdscr.addstr(ir, ix, status_text[:iw], curses.color_pair(7))
            ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            cpu_gauge = render_gauge(int(total_cpu), width=10)
            self.stdscr.addstr(ir, ix, f" Total CPU: [{cpu_gauge}] {total_cpu:4.1f}%", curses.color_pair(2) | curses.A_BOLD)
            ir += 1

            mem_gauge = render_gauge(min(100, int((total_mem / 4096) * 100)), width=10)
            self.stdscr.addstr(ir, ix, f"󰘚 Total RAM: [{mem_gauge}] {total_mem} MB", curses.color_pair(4) | curses.A_BOLD)
            ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            sub_ws_map = {}
            for c in wins:
                ws = c.get("workspace", {}).get("name", "other")
                sub_ws_map.setdefault(ws, []).append(c)

            self.stdscr.addstr(ir, ix, "󰍹 WORKSPACES IN LANE:", curses.color_pair(2) | curses.A_BOLD)
            ir += 1
            for sws, clist in sorted(sub_ws_map.items())[:4]:
                if ir < h - 14:
                    smem = sum(c.get("_mem_mb", 0) for c in clist)
                    scpu = sum(c.get("_cpu_pct", 0) for c in clist)
                    self.stdscr.addstr(ir, ix, f"• {sws:<13} {len(clist)} win(s)  {smem}M  {scpu:3.1f}%", curses.color_pair(7))
                    ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            hints = [
                ("[Enter/z]", "Collapse / Expand Lane"),
                ("[v/Space]", "Select / Deselect Lane"),
                ("[f]", "Freeze / Thaw Entire Lane"),
                ("[1-4]", "Apply Quota to Lane (10-75%)"),
                ("[( / )]", "CFS Weight ±25"),
                ("[M]", "Cgroup Memory Modal"),
                ("[0]", "Reset Lane to Defaults"),
                ("[x]", "Close All Windows in Lane"),
            ]
            self.stdscr.addstr(ir, ix, "󰓅 LANE BATCH CONTROLS:", curses.color_pair(2) | curses.A_BOLD)
            ir += 1
            for key_h, desc_h in hints:
                if ir < h - 4:
                    self.stdscr.addstr(ir, ix, f"{key_h:<11}", curses.color_pair(2) | curses.A_BOLD)
                    self.stdscr.addstr(ir, ix + 11, desc_h[: iw - 11], curses.color_pair(1))
                    ir += 1
        except curses.error:
            pass

    def render_inspector_workspace(self, ws_item, rx, ry, right_w, h):
        label = ws_item["label"]
        wins = ws_item["clients"]
        ws_name = ws_item["ws_name"]
        total_mem = ws_item["total_mem"]
        total_cpu = ws_item["total_cpu"]
        count = ws_item["count"]
        active_cnt = ws_item["active_cnt"]
        frozen_cnt = ws_item["frozen_cnt"]
        throt_cnt = ws_item["throt_cnt"]

        try:
            self.stdscr.addstr(ry, rx, f"╭─ {label[:right_w-6]} " + "─" * max(0, right_w - len(label) - 6) + "╮", curses.color_pair(2) | curses.A_BOLD)
            for r in range(ry + 1, h - 3):
                self.stdscr.addstr(r, rx, "│" + " " * (right_w - 2) + "│", curses.color_pair(7))
            self.stdscr.addstr(h - 4, rx, "╰" + "─" * (right_w - 2) + "╯", curses.color_pair(7))
        except curses.error:
            pass

        ir = ry + 1
        ix = rx + 2
        iw = right_w - 4

        try:
            self.stdscr.addstr(ir, ix, f"WORKSPACE SUMMARY: {count} Window(s)", curses.color_pair(1) | curses.A_BOLD)
            ir += 1
            status_parts = []
            if active_cnt: status_parts.append(f"● {active_cnt} active")
            if frozen_cnt: status_parts.append(f"❄ {frozen_cnt} frozen")
            if throt_cnt: status_parts.append(f"⚡ {throt_cnt} throttled")
            status_text = "  ".join(status_parts) or "All normal"
            self.stdscr.addstr(ir, ix, status_text[:iw], curses.color_pair(7))
            ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            cpu_gauge = render_gauge(int(total_cpu), width=10)
            self.stdscr.addstr(ir, ix, f" Total CPU: [{cpu_gauge}] {total_cpu:4.1f}%", curses.color_pair(2) | curses.A_BOLD)
            ir += 1

            mem_gauge = render_gauge(min(100, int((total_mem / 4096) * 100)), width=10)
            self.stdscr.addstr(ir, ix, f"󰘚 Total RAM: [{mem_gauge}] {total_mem} MB", curses.color_pair(4) | curses.A_BOLD)
            ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            app_map = {}
            for c in wins:
                cls = c.get("class", "unknown")
                app_map[cls] = app_map.get(cls, 0) + 1
            self.stdscr.addstr(ir, ix, "󰞌 APPLICATIONS IN WS:", curses.color_pair(8) | curses.A_BOLD)
            ir += 1
            app_str = ", ".join(f"{cls} ({cnt})" for cls, cnt in app_map.items())
            for line in textwrap.wrap(app_str, iw)[:3]:
                if ir < h - 13:
                    self.stdscr.addstr(ir, ix, line, curses.color_pair(1))
                    ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            hints = [
                ("[Enter/z]", "Collapse / Expand Workspace"),
                ("[v/Space]", "Select / Deselect Workspace"),
                ("[f]", "Freeze / Thaw Workspace"),
                ("[1-4]", "Apply Quota (10-75%)"),
                ("[( / )]", "CFS Weight ±25"),
                ("[M]", "Cgroup Memory Modal"),
                ("[0]", "Reset Workspace Defaults"),
                ("[x]", "Close All in Workspace"),
            ]
            self.stdscr.addstr(ir, ix, "󰓅 WORKSPACE ACTIONS:", curses.color_pair(2) | curses.A_BOLD)
            ir += 1
            for key_h, desc_h in hints:
                if ir < h - 4:
                    self.stdscr.addstr(ir, ix, f"{key_h:<11}", curses.color_pair(2) | curses.A_BOLD)
                    self.stdscr.addstr(ir, ix + 11, desc_h[: iw - 11], curses.color_pair(1))
                    ir += 1
        except curses.error:
            pass

    def render_inspector_group(self, group_item, rx, ry, right_w, h):
        label = group_item["label"]
        wins = group_item["clients"]
        total_mem = group_item["total_mem"]
        total_cpu = group_item["total_cpu"]
        count = group_item["count"]
        active_cnt = group_item["active_cnt"]
        frozen_cnt = group_item["frozen_cnt"]
        throt_cnt = group_item["throt_cnt"]

        try:
            self.stdscr.addstr(ry, rx, f"╭─ {label[:right_w-6]} " + "─" * max(0, right_w - len(label) - 6) + "╮", curses.color_pair(2) | curses.A_BOLD)
            for r in range(ry + 1, h - 3):
                self.stdscr.addstr(r, rx, "│" + " " * (right_w - 2) + "│", curses.color_pair(7))
            self.stdscr.addstr(h - 4, rx, "╰" + "─" * (right_w - 2) + "╯", curses.color_pair(7))
        except curses.error:
            pass

        ir = ry + 1
        ix = rx + 2
        iw = right_w - 4

        try:
            self.stdscr.addstr(ir, ix, f"GROUP SUMMARY: {count} Window(s)", curses.color_pair(1) | curses.A_BOLD)
            ir += 1
            status_parts = []
            if active_cnt: status_parts.append(f"● {active_cnt} active")
            if frozen_cnt: status_parts.append(f"❄ {frozen_cnt} frozen")
            if throt_cnt: status_parts.append(f"⚡ {throt_cnt} throttled")
            status_text = "  ".join(status_parts) or "All normal"
            self.stdscr.addstr(ir, ix, status_text[:iw], curses.color_pair(7))
            ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            # Aggregate CPU
            cpu_gauge = render_gauge(int(total_cpu), width=10)
            self.stdscr.addstr(ir, ix, f" Total CPU: [{cpu_gauge}] {total_cpu:4.1f}%", curses.color_pair(2) | curses.A_BOLD)
            ir += 1

            # Aggregate RAM
            mem_gauge = render_gauge(min(100, int((total_mem / 4096) * 100)), width=10)
            self.stdscr.addstr(ir, ix, f"󰘚 Total RAM: [{mem_gauge}] {total_mem} MB", curses.color_pair(4) | curses.A_BOLD)
            ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            # Sub-workspaces in this group
            sub_ws_map = {}
            for c in wins:
                ws = c.get("workspace", {}).get("name", "other")
                sub_ws_map.setdefault(ws, []).append(c)

            self.stdscr.addstr(ir, ix, "󰍹 SUB-WORKSPACES IN GROUP:", curses.color_pair(2) | curses.A_BOLD)
            ir += 1
            for sws, clist in sorted(sub_ws_map.items())[:4]:
                if ir < h - 14:
                    smem = sum(c.get("_mem_mb", 0) for c in clist)
                    scpu = sum(c.get("_cpu_pct", 0) for c in clist)
                    self.stdscr.addstr(ir, ix, f"• {sws:<13} {len(clist)} win(s)  {smem}M  {scpu:3.1f}%", curses.color_pair(7))
                    ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            # Applications breakdown
            app_map = {}
            for c in wins:
                cls = c.get("class", "unknown")
                app_map[cls] = app_map.get(cls, 0) + 1
            self.stdscr.addstr(ir, ix, "󰞌 APPLICATIONS:", curses.color_pair(8) | curses.A_BOLD)
            ir += 1
            app_str = ", ".join(f"{cls} ({cnt})" for cls, cnt in app_map.items())
            for line in textwrap.wrap(app_str, iw)[:2]:
                if ir < h - 11:
                    self.stdscr.addstr(ir, ix, line, curses.color_pair(1))
                    ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            hints = [
                ("[Enter/z]", "Collapse / Expand Group"),
                ("[v/Space]", "Select / Deselect Group"),
                ("[f]", "Freeze / Thaw Entire Group"),
                ("[1-4]", "Apply Quota to Group (25-75%)"),
                ("[0]", "Reset Group to Defaults"),
                ("[x]", "Close All Windows in Group"),
            ]
            self.stdscr.addstr(ir, ix, "󰓅 GROUP BATCH CONTROLS:", curses.color_pair(2) | curses.A_BOLD)
            ir += 1
            for key_h, desc_h in hints:
                if ir < h - 4:
                    self.stdscr.addstr(ir, ix, f"{key_h:<11}", curses.color_pair(2) | curses.A_BOLD)
                    self.stdscr.addstr(ir, ix + 11, desc_h[: iw - 11], curses.color_pair(1))
                    ir += 1
        except curses.error:
            pass

    def render_inspector_client(self, target_client, rx, ry, right_w, h):
        try:
            self.stdscr.addstr(ry, rx, "╭─ 󰋼 WINDOW INSPECTOR " + "─" * max(0, right_w - 24) + "╮", curses.color_pair(2) | curses.A_BOLD)
            for r in range(ry + 1, h - 3):
                self.stdscr.addstr(r, rx, "│" + " " * (right_w - 2) + "│", curses.color_pair(7))
            self.stdscr.addstr(h - 4, rx, "╰" + "─" * (right_w - 2) + "╯", curses.color_pair(7))
        except curses.error:
            pass

        pid = target_client.get("pid", 0)
        cclass = target_client.get("class", "Unknown")
        addr = target_client.get("address", "")
        ws = target_client.get("workspace", {}).get("name", "")
        title = target_client.get("title", "")
        is_floating = target_client.get("floating", False)

        cg_info = target_client.get("_info") or read_cgroup_info_for_window(target_client)
        metrics_data = target_client.get("_metrics") or self.metrics.update_and_get(pid, cg_info["cgroups"])

        ir = ry + 1
        ix = rx + 2
        iw = right_w - 4

        try:
            # Overview
            self.stdscr.addstr(ir, ix, f"[{cclass}] PID: {pid}", curses.color_pair(1) | curses.A_BOLD)
            ir += 1
            self.stdscr.addstr(ir, ix, f"Workspace: {ws}  Floating: {is_floating}", curses.color_pair(7))
            ir += 1
            t_lines = textwrap.wrap(f"Title: {title}", iw)
            for tl in t_lines[:2]:
                self.stdscr.addstr(ir, ix, tl, curses.color_pair(1))
                ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            # Cgroups
            cgs = cg_info["cgroups"]
            self.stdscr.addstr(ir, ix, f"󰘚 CGROUP SCOPES ({len(cgs)}):", curses.color_pair(2) | curses.A_BOLD)
            ir += 1
            for cg in cgs[:2]:
                base_name = os.path.basename(cg)
                self.stdscr.addstr(ir, ix, f"• {base_name[:iw-2]}", curses.color_pair(7))
                ir += 1
            if len(cgs) > 2:
                self.stdscr.addstr(ir, ix, f"  +{len(cgs)-2} more scope(s)", curses.color_pair(7))
                ir += 1

            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1

            # CPU Gauges
            cpu_pct = metrics_data["cpu_pct"]
            cpu_gauge = render_gauge(int(cpu_pct), width=10)
            self.stdscr.addstr(ir, ix, f" CPU: [{cpu_gauge}] {cpu_pct:4.1f}%", curses.color_pair(2) | curses.A_BOLD)
            ir += 1

            quota_pct = cg_info["cpu_max_pct"]
            quota_disp = "max" if cg_info["cpu_max"] == "max" else f"{quota_pct}%"
            self.stdscr.addstr(ir, ix, f"Quota: {quota_disp}  Weight: {cg_info['cpu_weight']}  Idle: {cg_info['cpu_idle']}", curses.color_pair(5))
            ir += 1

            # RAM
            mem_curr = cg_info["mem_curr"]
            mem_peak = cg_info.get("mem_peak", mem_curr)
            mem_gauge = render_gauge(min(100, int((mem_curr / 2048) * 100)), width=10)
            self.stdscr.addstr(ir, ix, f"󰘚 RAM: [{mem_gauge}] {mem_curr} MB (Peak: {mem_peak} MB)", curses.color_pair(4) | curses.A_BOLD)
            ir += 1
            high_disp = cg_info.get("mem_high_disp", "max")
            max_disp = cg_info.get("mem_max_disp", "max")
            self.stdscr.addstr(ir, ix, f"High: {high_disp}  Max: {max_disp}  [M] Memory Controls", curses.color_pair(7))
            ir += 1

            # I/O & PSI
            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1
            disk_r = fmt_rate(metrics_data["disk_rate"])
            self.stdscr.addstr(ir, ix, f"󰋊 I/O Rate: {disk_r}  Total: {fmt_bytes(metrics_data['disk_total'])}", curses.color_pair(1))
            ir += 1
            self.stdscr.addstr(ir, ix, f"󰓅 PSI Stall: CPU {cg_info['psi_cpu']}%  Mem {cg_info['psi_mem']}%", curses.color_pair(8))
            ir += 1

            # Hotkey Cheatsheet
            self.stdscr.addstr(ir, rx, "├" + "─" * (right_w - 2) + "┤", curses.color_pair(7))
            ir += 1
            hints = [
                ("[Enter]", "Focus & Switch (follows ws)"),
                ("[f]", "Toggle Freeze / Thaw (0% CPU)"),
                ("[ / ]", "Quota ±5%  ({ / } ±25%)"),
                ("[( / )]", "CFS Weight ±25"),
                ("[M]", "Cgroup Memory Limits & Reclaim"),
                ("[0]", "Reset Target Limits"),
                ("[R/X]", "System-wide Reset All"),
                ("[w/m]", "Move to Workspace"),
                ("[t]", "Toggle Float  [x] Close  [K] Kill"),
            ]
            for key_h, desc_h in hints:
                if ir < h - 4:
                    self.stdscr.addstr(ir, ix, f"{key_h:<8}", curses.color_pair(2) | curses.A_BOLD)
                    self.stdscr.addstr(ir, ix + 8, desc_h[: iw - 8], curses.color_pair(1))
                    ir += 1
        except curses.error:
            pass

    def render_tab_profiles(self):
        h, w = self.stdscr.getmaxyx()
        card_w = min(w - 6, 92)
        top = 5
        left = 3

        try:
            self.stdscr.addstr(top, left, "╭─ 🚀 SYSTEM WORKFLOW PROFILES & BATCH PRESETS " + "─" * max(0, card_w - 48) + "╮", curses.color_pair(2) | curses.A_BOLD)
        except curses.error:
            pass

        r = top + 1
        for i, (key, title, desc) in enumerate(self.profiles):
            if r >= h - 4:
                break
            is_cursor = i == self.profile_cursor
            try:
                line_empty = "│" + " " * (card_w - 2) + "│"
                self.stdscr.addstr(r, left, line_empty, curses.color_pair(7))

                arrow = "› " if is_cursor else "  "
                self.stdscr.addstr(r, left + 2, arrow, curses.color_pair(2) | curses.A_BOLD if is_cursor else curses.color_pair(7))
                self.stdscr.addstr(r, left + 5, f"[{key}]", curses.color_pair(2) | curses.A_BOLD)

                row_style = curses.color_pair(3) | curses.A_BOLD if is_cursor else curses.color_pair(1) | curses.A_BOLD
                self.stdscr.addstr(r, left + 10, title, row_style)

                desc_x = left + 44
                if desc_x < left + card_w - 4:
                    avail = (left + card_w - 2) - desc_x
                    self.stdscr.addstr(r, desc_x, desc[:avail], curses.color_pair(7))

                r += 1
                if i < len(self.profiles) - 1 and r < h - 4:
                    sep = "├" + "─" * (card_w - 2) + "┤"
                    self.stdscr.addstr(r, left, sep, curses.color_pair(7))
                    r += 1
            except curses.error:
                pass

        try:
            self.stdscr.addstr(r, left, "╰" + "─" * (card_w - 2) + "╯", curses.color_pair(7))
        except curses.error:
            pass

        self.draw_footer("[1-7 / Enter] Activate Profile   [j/k] Navigate   [Tab] Switch View   [q] Quit")

    def render_help_modal(self):
        h, w = self.stdscr.getmaxyx()
        modal_w = min(w - 6, 88)
        modal_h = min(h - 4, 30)
        top = max(1, (h - modal_h) // 2)
        left = max(2, (w - modal_w) // 2)

        try:
            self.stdscr.addstr(top, left, "╭─ 󰋼 HYPRLAND CONTROL PANEL REFERENCE " + "─" * max(0, modal_w - 40) + "╮", curses.color_pair(2) | curses.A_BOLD)
            for r in range(top + 1, top + modal_h - 1):
                self.stdscr.addstr(r, left, "│" + " " * (modal_w - 2) + "│", curses.color_pair(7))
            self.stdscr.addstr(top + modal_h - 1, left, "╰" + "─" * (modal_w - 32) + " Press [h/Esc/q] to close ─╯", curses.color_pair(2))
        except curses.error:
            pass

        r = top + 1
        x = left + 3
        inner_w = modal_w - 6

        sections = [
            ("NAVIGATION & TREE HIERARCHY", [
                ("[Tab] / [1-2]", "Switch tabs: Windows & Resources, System Profiles"),
                ("[j] / [k] / [↑] [↓]", "Instant responsive navigation (vim keys supported)"),
                ("[Enter]", "Focus window & switch workspace | Fold/Unfold tree group"),
                ("[z] / [Z]", "Fold/unfold current group [z] | Toggle collapse/expand all [Z]"),
                ("[←] / [→]", "Collapse group / jump to parent [←] | Expand group [→]"),
                ("[v] / [Space]", "Toggle select window | Batch select/deselect entire group"),
                ("[/] / [Esc]", "Search filter [/] | Instant exit or clear selection [Esc]"),
                ("[s]", "Cycle hierarchy mode (Workspaces, App Class, CPU%, Memory)"),
            ]),
            ("CGROUP TUNING & SLIDERS", [
                ("[f] / [t]", "Freeze / Thaw target in RAM at 0% CPU without quitting"),
                ("[ / ]", "Dynamic CPU Quota Slider (adjust ceiling ±5%) | [{ / }] (±25%)"),
                ("[(] / [)]", "CFS Scheduling Priority Weight (adjust share ±25) | [, / .]"),
                ("[1-4] / [0]", "Quick CPU Quota presets: 10%, 25%, 50%, 75% | [0]=Reset target"),
                ("[M]", "Cgroup Memory Modal: memory.high soft limits, memory.max hard ceilings"),
                ("[C]", "Force instant 250MB kernel page cache reclaim"),
                ("[R] / [X]", "System-wide reset: restore all defaults & unfreeze everything"),
            ]),
            ("HYPRLAND WINDOW ACTIONS", [
                ("[Enter]", "Focus & Switch to window (guaranteed to follow workspace)"),
                ("[w] / [m]", "Move window(s) to another workspace or anchor lane"),
                ("[t]", "Toggle floating mode in Hyprland"),
                ("[x] / [K]", "Close window / group [x] | Terminate process tree [K]"),
            ]),
        ]

        for sec_title, keys in sections:
            try:
                if r < top + modal_h - 2:
                    self.stdscr.addstr(r, x, f"▶ {sec_title}", curses.color_pair(2) | curses.A_BOLD)
                    r += 1
                for k, desc in keys:
                    if r >= top + modal_h - 2:
                        break
                    self.stdscr.addstr(r, x, f"• {k:<15}: ", curses.color_pair(1) | curses.A_BOLD)
                    self.stdscr.addstr(r, x + 18, desc[: inner_w - 18], curses.color_pair(7))
                    r += 1
                r += 1
            except curses.error:
                pass

    def run(self):
        self.update_clients()
        self.running = True
        self.worker_thread = threading.Thread(target=self._background_worker, daemon=True)
        self.worker_thread.start()

        while self.running:
            # Check if background worker has new client data
            if self.pending_rebuild and not self.show_help and not self.show_mem_modal:
                with self.data_lock:
                    self.clients = self._pending_clients
                    if not self.initial_active_set and self._pending_active_addr:
                        self.active_addr = self._pending_active_addr
                    active_ws = self._pending_active_ws
                    self.pending_rebuild = False
                self.apply_search_and_build(active_ws=active_ws, preserve_cursor=True)

            self.stdscr.erase()
            self.draw_banner()

            if self.show_help:
                self.render_help_modal()
            elif self.show_mem_modal:
                self.render_mem_modal()
            else:
                if self.tab == 0:
                    self.render_tab_windows()
                elif self.tab == 1:
                    self.render_tab_profiles()

            self.stdscr.refresh()

            self.stdscr.timeout(40)  # 25 FPS responsive UI loop
            try:
                key = self.stdscr.getch()
            except curses.error:
                key = -1

            if key == -1:
                continue

            self.last_input_time = time.time()

            if key in (ord("q"), ord("Q")):
                if self.show_help:
                    self.show_help = False
                    continue
                if self.show_mem_modal:
                    self.show_mem_modal = False
                    continue
                if self.search_query:
                    self.search_query = ""
                    self.set_flash("Cleared search filter.")
                    self.apply_search_and_build()
                    continue
                break

            if key == curses.KEY_RESIZE:
                continue

            self.handle_input(key)

        self.running = False

    def handle_input(self, key):
        if self.show_help:
            if key in (ord("h"), ord("H"), 27, ord("q"), ord("Q"), ord("?")):
                self.show_help = False
            return

        # Handle Memory Modal input
        if self.show_mem_modal:
            if key in (ord("q"), ord("Q"), 27, ord("m"), ord("M")):
                self.show_mem_modal = False
                return
            elif key == ord("1"):
                self.execute_knob_on_targets("memory.high", "250M")
                self.show_mem_modal = False
                return
            elif key == ord("2"):
                self.execute_knob_on_targets("memory.high", "500M")
                self.show_mem_modal = False
                return
            elif key == ord("3"):
                self.execute_knob_on_targets("memory.high", "1G")
                self.show_mem_modal = False
                return
            elif key == ord("4"):
                self.execute_knob_on_targets("memory.high", "2G")
                self.show_mem_modal = False
                return
            elif key == ord("5"):
                self.execute_knob_on_targets("memory.high", "4G")
                self.show_mem_modal = False
                return
            elif key == ord("6"):
                self.execute_knob_on_targets("memory.max", "1G")
                self.show_mem_modal = False
                return
            elif key == ord("7"):
                self.execute_knob_on_targets("memory.max", "2G")
                self.show_mem_modal = False
                return
            elif key == ord("8"):
                val = self.prompt_string("Custom memory.high (e.g. 750M, 1.5G, 3G)")
                if val:
                    self.execute_knob_on_targets("memory.high", val)
                self.show_mem_modal = False
                return
            elif key == ord("9"):
                val = self.prompt_string("Custom memory.max (e.g. 1.5G, 3G)")
                if val:
                    self.execute_knob_on_targets("memory.max", val)
                self.show_mem_modal = False
                return
            elif key in (ord("c"), ord("C")):
                targets = self.get_effective_targets()
                for c in targets:
                    apply_knob_to_window(c, "memory.reclaim", "250M")
                self.set_flash("✓ Forced 250MB page cache reclaim")
                self.show_mem_modal = False
                return
            elif key == ord("0"):
                self.execute_knob_on_targets("memory.high", "max")
                self.execute_knob_on_targets("memory.max", "max")
                self.execute_knob_on_targets("memory.swap.max", "max")
                self.set_flash("✓ Cleared all memory limits (high=max, max=max)")
                self.show_mem_modal = False
                return
            return

        # Global Tab Switching
        if key in (9, ord("\t")):  # Tab
            self.tab = (self.tab + 1) % len(self.tab_names)
            return
        elif key == curses.KEY_BTAB:  # Shift+Tab
            self.tab = (self.tab - 1) % len(self.tab_names)
            return

        # Direct Tab jumping via numbers (when not in search)
        if not self.searching and self.tab != 0:
            if key == ord("1"):
                self.tab = 0
                return
            elif key == ord("2"):
                self.tab = 1
                return

        if key in (ord("h"), ord("H"), ord("?")):
            self.show_help = True
            return

        # Global Esc / Quick Exit
        if key in (27, ord("b"), ord("B")):  # Esc or b
            if self.search_query:
                self.search_query = ""
                self.set_flash("Cleared search filter.")
                self.apply_search_and_build()
                return
            if self.selected_addrs or self.bulk_target:
                self.selected_addrs.clear()
                self.bulk_target = None
                self.set_flash("Cleared selection.")
                return
            sys.exit(0)

        # ==========================================
        # TAB 0: WINDOWS & RESOURCES
        # ==========================================
        if self.tab == 0:
            # Navigation - INSTANT: only alters cursor index without blocking
            if key in (curses.KEY_DOWN, ord("j")):
                if self.cursor_idx < len(self.tree_items) - 1:
                    self.cursor_idx += 1
            elif key in (curses.KEY_UP, ord("k")):
                if self.cursor_idx > 0:
                    self.cursor_idx -= 1
            elif key in (curses.KEY_HOME, ord("g")):
                self.cursor_idx = 0
            elif key in (curses.KEY_END, ord("G")):
                self.cursor_idx = max(0, len(self.tree_items) - 1)
            elif key == curses.KEY_PPAGE:
                self.cursor_idx = max(0, self.cursor_idx - 8)
            elif key == curses.KEY_NPAGE:
                self.cursor_idx = min(max(0, len(self.tree_items) - 1), self.cursor_idx + 8)

            # Left/Right arrow 2-level tree navigation
            elif key == curses.KEY_LEFT:
                if self.tree_items and 0 <= self.cursor_idx < len(self.tree_items):
                    cur = self.tree_items[self.cursor_idx]
                    if cur["type"] == "lane":
                        lk = cur["lane_key"]
                        if lk not in self.collapsed_lanes:
                            self.collapsed_lanes.add(lk)
                            self.set_flash(f"Collapsed: {cur['label']}")
                            self.build_tree_items()
                    elif cur["type"] == "workspace":
                        wk = cur["ws_name"]
                        if wk not in self.collapsed_workspaces:
                            self.collapsed_workspaces.add(wk)
                            self.set_flash(f"Collapsed: {cur['label']}")
                            self.build_tree_items()
                        else:
                            # Already collapsed: jump up to parent lane!
                            parent_lk = cur["lane_key"]
                            for p_idx, ti in enumerate(self.tree_items):
                                if ti["type"] == "lane" and ti.get("lane_key") == parent_lk:
                                    self.cursor_idx = p_idx
                                    break
                    elif cur["type"] == "client":
                        # Jump up to parent workspace!
                        parent_ws = cur.get("ws_name")
                        for p_idx, ti in enumerate(self.tree_items):
                            if ti["type"] == "workspace" and ti.get("ws_name") == parent_ws:
                                self.cursor_idx = p_idx
                                break
                    elif cur["type"] == "group":
                        gid = cur.get("group_id")
                        if gid not in self.collapsed_groups:
                            self.collapsed_groups.add(gid)
                            self.build_tree_items()

            elif key == curses.KEY_RIGHT:
                if self.tree_items and 0 <= self.cursor_idx < len(self.tree_items):
                    cur = self.tree_items[self.cursor_idx]
                    if cur["type"] == "lane":
                        lk = cur["lane_key"]
                        if lk in self.collapsed_lanes:
                            self.collapsed_lanes.remove(lk)
                            self.set_flash(f"Expanded: {cur['label']}")
                            self.build_tree_items()
                        elif self.cursor_idx + 1 < len(self.tree_items):
                            self.cursor_idx += 1
                    elif cur["type"] == "workspace":
                        wk = cur["ws_name"]
                        if wk in self.collapsed_workspaces:
                            self.collapsed_workspaces.remove(wk)
                            self.set_flash(f"Expanded: {cur['label']}")
                            self.build_tree_items()
                        elif self.cursor_idx + 1 < len(self.tree_items):
                            self.cursor_idx += 1
                    elif cur["type"] == "group":
                        gid = cur.get("group_id")
                        if gid in self.collapsed_groups:
                            self.collapsed_groups.remove(gid)
                            self.build_tree_items()

            # Cycle Sort Mode
            elif key in (ord("s"), ord("S")):
                modes = ["workspace", "cpu", "mem", "state", "class"]
                cur_i = modes.index(self.sort_mode) if self.sort_mode in modes else 0
                self.sort_mode = modes[(cur_i + 1) % len(modes)]
                self.set_flash(f"Hierarchy Mode: By {self.sort_mode.capitalize()}")
                self.build_tree_items()

            # Search / Filter
            elif key == ord("/"):
                query = self.prompt_string("Search windows")
                self.search_query = query.strip()
                self.cursor_idx = 0
                self.apply_search_and_build()

            # Selection
            elif key in (ord("v"), ord("V"), ord(" ")):
                if self.tree_items and 0 <= self.cursor_idx < len(self.tree_items):
                    cur = self.tree_items[self.cursor_idx]
                    if cur["type"] == "client":
                        addr = cur["client"].get("address")
                        if addr:
                            if addr in self.selected_addrs:
                                self.selected_addrs.remove(addr)
                            else:
                                self.selected_addrs.add(addr)
                            self.bulk_target = None
                    elif cur["type"] in ("lane", "workspace", "group"):
                        grp_addrs = [c.get("address") for c in cur.get("clients", []) if c.get("address")]
                        if all(a in self.selected_addrs for a in grp_addrs):
                            for a in grp_addrs:
                                self.selected_addrs.discard(a)
                            self.set_flash(f"Deselected: {cur['label']}")
                        else:
                            for a in grp_addrs:
                                self.selected_addrs.add(a)
                            self.set_flash(f"Selected all in: {cur['label']}")
                        self.bulk_target = None

            elif key in (ord("a"), ord("A")):
                self.selected_addrs.clear()
                self.bulk_target = ("--active", None)
                self.set_flash("Target set: Active Focused Window")
            elif key in (ord("i"), ord("I")):
                self.selected_addrs.clear()
                self.bulk_target = ("--inactive", None)
                self.set_flash("Target set: All Inactive Windows")
            elif key == ord("*"):
                self.selected_addrs.clear()
                self.bulk_target = ("--all", None)
                self.set_flash("Target set: ALL Windows across system")

            # Close / Unselect
            elif key in (ord("u"), ord("x")):
                if self.selected_addrs or self.bulk_target:
                    self.selected_addrs.clear()
                    self.bulk_target = None
                    self.set_flash("Cleared selection.")
                elif key == ord("x"):
                    targets = self.get_effective_targets()
                    if not targets:
                        self.set_flash("No targets to close.")
                    elif len(targets) > 1:
                        confirm = self.prompt_string(f"Close {len(targets)} windows? [y/N]")
                        if confirm.lower() in ("y", "yes"):
                            for c in targets:
                                addr = c.get("address")
                                if addr:
                                    hypr_dispatch("closewindow", f"address:{addr}")
                            self.set_flash(f"✓ Closed {len(targets)} windows.")
                        else:
                            self.set_flash("Close cancelled.")
                    else:
                        addr = targets[0].get("address")
                        if addr:
                            hypr_dispatch("closewindow", f"address:{addr}")
                        self.set_flash("Closed window.")

            # Enter: Switch Focus to window (follows workspace) OR Fold/Unfold Lane/Workspace
            elif key in (10, 13, curses.KEY_ENTER):
                if self.tree_items and 0 <= self.cursor_idx < len(self.tree_items):
                    cur = self.tree_items[self.cursor_idx]
                    if cur["type"] == "client":
                        focus_window_and_switch(cur["client"])
                        sys.exit(0)
                    elif cur["type"] == "lane":
                        lk = cur["lane_key"]
                        if lk in self.collapsed_lanes:
                            self.collapsed_lanes.remove(lk)
                            self.set_flash(f"Expanded: {cur['label']}")
                        else:
                            self.collapsed_lanes.add(lk)
                            self.set_flash(f"Collapsed: {cur['label']}")
                        self.build_tree_items()
                    elif cur["type"] == "workspace":
                        wk = cur["ws_name"]
                        if wk in self.collapsed_workspaces:
                            self.collapsed_workspaces.remove(wk)
                            self.set_flash(f"Expanded: {cur['label']}")
                        else:
                            self.collapsed_workspaces.add(wk)
                            self.set_flash(f"Collapsed: {cur['label']}")
                        self.build_tree_items()
                    elif cur["type"] == "group":
                        gid = cur["group_id"]
                        if gid in self.collapsed_groups:
                            self.collapsed_groups.remove(gid)
                        else:
                            self.collapsed_groups.add(gid)
                        self.build_tree_items()

            # Fold / Unfold with 'z'
            elif key == ord("z"):
                if self.tree_items and 0 <= self.cursor_idx < len(self.tree_items):
                    cur = self.tree_items[self.cursor_idx]
                    if cur["type"] == "lane":
                        lk = cur["lane_key"]
                        if lk in self.collapsed_lanes:
                            self.collapsed_lanes.remove(lk)
                        else:
                            self.collapsed_lanes.add(lk)
                        self.build_tree_items()
                    elif cur["type"] == "workspace":
                        wk = cur["ws_name"]
                        if wk in self.collapsed_workspaces:
                            self.collapsed_workspaces.remove(wk)
                        else:
                            self.collapsed_workspaces.add(wk)
                        self.build_tree_items()
                    elif cur["type"] == "client":
                        pw = cur.get("ws_name")
                        if pw:
                            if pw in self.collapsed_workspaces:
                                self.collapsed_workspaces.remove(pw)
                            else:
                                self.collapsed_workspaces.add(pw)
                            self.build_tree_items()
                    elif cur["type"] == "group":
                        gid = cur.get("group_id")
                        if gid:
                            if gid in self.collapsed_groups:
                                self.collapsed_groups.remove(gid)
                            else:
                                self.collapsed_groups.add(gid)
                            self.build_tree_items()

            # Toggle collapse / expand all groups with Shift+Z
            elif key == ord("Z"):
                self.toggle_collapse_all()

            # Move window to workspace (supports 'w' or 'm')
            elif key in (ord("w"), ord("W"), ord("m")):
                targets = self.get_effective_targets()
                if targets:
                    target_ws = self.prompt_string("Move to Workspace (e.g. A:0, Z:0, special:scratchpad)")
                    if target_ws:
                        for c in targets:
                            addr = c.get("address")
                            if addr:
                                hypr_dispatch("movetoworkspace", f"name:{target_ws},address:{addr}")
                        self.set_flash(f"✓ Moved to {target_ws}")

            # Toggle Floating in Hyprland
            elif key in (ord("t"), ord("T")):
                targets = self.get_effective_targets()
                for c in targets:
                    addr = c.get("address")
                    if addr:
                        hypr_dispatch("togglefloating", f"address:{addr}")
                self.set_flash("Toggled floating mode")

            # Cgroup Freeze / Thaw
            elif key in (ord("f"), ord("F")):
                self.toggle_freeze_targets()

            # CPU Quota Sliders: [ ] for ±5%, { } for ±25%
            elif key == ord("["):
                self.adjust_cpu_quota_targets(-5)
            elif key == ord("]"):
                self.adjust_cpu_quota_targets(5)
            elif key == ord("{"):
                self.adjust_cpu_quota_targets(-25)
            elif key == ord("}"):
                self.adjust_cpu_quota_targets(25)

            # CPU CFS Weight: ( ) or < > or , . or - + for ±25
            elif key in (ord("("), ord("<"), ord(","), ord("-")):
                self.adjust_cpu_weight_targets(-25)
            elif key in (ord(")"), ord(">"), ord("."), ord("+"), ord("=")):
                self.adjust_cpu_weight_targets(25)

            # Presets
            elif key == ord("1"):
                self.execute_knob_on_targets("cpu.max", "10000 100000")
            elif key == ord("2"):
                self.execute_knob_on_targets("cpu.max", "25000 100000")
            elif key == ord("3"):
                self.execute_knob_on_targets("cpu.max", "50000 100000")
            elif key == ord("4"):
                self.execute_knob_on_targets("cpu.max", "75000 100000")

            # Memory controls: M opens memory modal, C forces page cache reclaim
            elif key == ord("M"):
                self.show_mem_modal = True
            elif key == ord("C"):
                targets = self.get_effective_targets()
                for c in targets:
                    apply_knob_to_window(c, "memory.reclaim", "250M")
                self.set_flash("✓ Forced 250MB page cache reclaim")

            # Reset selected / target limits
            elif key == ord("0"):
                self.reset_selected_targets()

            # System-wide reset (Shift+R or Shift+X)
            elif key in (ord("R"), ord("X")):
                self.reset_all_system()

            # Kill process tree (Shift+K)
            elif key == ord("K"):
                targets = self.get_effective_targets()
                desc = self.get_target_description()
                confirm = self.prompt_string(f"Terminate {desc}? [y/N]")
                if confirm.lower() in ("y", "yes"):
                    for c in targets:
                        kill_window_process_tree(c)
                    self.set_flash(f"✓ Terminated {desc}")
                    notify("Control Panel: Kill", f"Terminated {desc}")
                    self.selected_addrs.clear()
                    self.bulk_target = None
                else:
                    self.set_flash("Kill cancelled.")

        # ==========================================
        # TAB 1: SYSTEM PROFILES
        # ==========================================
        elif self.tab == 1:
            if key in (curses.KEY_DOWN, ord("j")):
                if self.profile_cursor < len(self.profiles) - 1:
                    self.profile_cursor += 1
            elif key in (curses.KEY_UP, ord("k")):
                if self.profile_cursor > 0:
                    self.profile_cursor -= 1
            elif key in (10, 13, curses.KEY_ENTER):
                self.execute_profile(self.profile_cursor)
            elif ord("1") <= key <= ord("7"):
                idx = key - ord("1")
                if idx < len(self.profiles):
                    self.profile_cursor = idx
                    self.execute_profile(idx)


def main():
    curses.wrapper(lambda stdscr: ControlPanelApp(stdscr).run())


if __name__ == "__main__":
    main()
