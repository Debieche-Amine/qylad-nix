#!/usr/bin/env python3
import argparse
import glob
import json
import os
import subprocess
import sys

STATE_FILE = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR", f"/tmp/run-{os.getuid()}"),
    "power-profile-state.json"
)

# Frequency mappings (based on 4.70 GHz maximum turbo):
# 8%  = 400 MHz (hardware minimum floor)
# 17% = 800 MHz
# 23% = 1.1 GHz
# 34% = 1.6 GHz
# 43% = 2.0 GHz
# 55% = 2.6 GHz
# 64% = 3.0 GHz
# 74% = 3.5 GHz
# 85% = 4.0 GHz
# 100% = 4.7 GHz (max turbo)

PROFILES = {
    "performance": {
        "name": "Performance",
        "glyph": "󰓅",
        "short": "Perf",
        "governor": "performance",
        "epp": "performance",
        "turbo": True,
        "min_perf_pct": 23,   # 1.1 GHz
        "max_perf_pct": 100,  # 4.7 GHz (max)
    },
    "balanced": {
        "name": "Balanced",
        "glyph": "󰾆",
        "short": "Bal",
        "governor": "powersave",
        "epp": "balance_performance",
        "turbo": False,       # Turbo OFF
        "min_perf_pct": 8,    # 400 MHz
        "max_perf_pct": 43,   # 2.0 GHz
    },
    "powersaver": {
        "name": "Power Saver",
        "glyph": "󰌪",
        "short": "Eco",
        "governor": "powersave",
        "epp": "power",
        "turbo": False,       # Turbo OFF
        "min_perf_pct": 8,    # 400 MHz
        "max_perf_pct": 17,   # 800 MHz
    },
}

BACKEND_BIN = "/run/current-system/sw/bin/power-profile-backend"


def read_sysfs(path, default=""):
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except Exception:
        return default


def write_sysfs(path, value):
    try:
        with open(path, "w") as f:
            f.write(str(value))
        return True
    except Exception:
        return False


def get_hw_state():
    gov = read_sysfs("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor", "powersave")
    epp = read_sysfs("/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference", "balance_performance")
    no_turbo = read_sysfs("/sys/devices/system/cpu/intel_pstate/no_turbo", "0")
    turbo = (no_turbo == "0")

    min_perf = read_sysfs("/sys/devices/system/cpu/intel_pstate/min_perf_pct", "8")
    try:
        min_perf_pct = int(min_perf)
    except ValueError:
        min_perf_pct = 8

    max_perf = read_sysfs("/sys/devices/system/cpu/intel_pstate/max_perf_pct", "100")
    try:
        max_perf_pct = int(max_perf)
    except ValueError:
        max_perf_pct = 100

    # CPU Freq
    freqs = []
    freq_files = glob.glob("/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq")
    for ff in freq_files:
        try:
            val = read_sysfs(ff)
            if val:
                freqs.append(int(val))
        except Exception:
            pass
    if freqs:
        avg_freq_mhz = sum(freqs) / len(freqs) / 1000.0
    else:
        avg_freq_mhz = 0.0

    # CPU Temp
    temp_c = 0
    for tz in glob.glob("/sys/class/thermal/thermal_zone*/temp"):
        try:
            t = int(read_sysfs(tz, "0"))
            if 20000 <= t <= 110000:
                temp_c = int(t / 1000)
                break
        except Exception:
            pass

    return {
        "governor": gov,
        "epp": epp,
        "turbo": turbo,
        "min_perf_pct": min_perf_pct,
        "max_perf_pct": max_perf_pct,
        "avg_freq_ghz": round(avg_freq_mhz / 1000.0, 2),
        "temp_c": temp_c,
    }


def load_state():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {"base_profile": "balanced"}


def save_state(state):
    try:
        os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=2)
    except Exception:
        pass


def match_profile(hw):
    for key, p in PROFILES.items():
        if (
            hw["governor"] == p["governor"]
            and hw["epp"] == p["epp"]
            and hw["turbo"] == p["turbo"]
            and abs(hw["min_perf_pct"] - p["min_perf_pct"]) <= 1
            and abs(hw["max_perf_pct"] - p["max_perf_pct"]) <= 1
        ):
            return key
    return "custom"


def notify_waybar():
    try:
        subprocess.run(["pkill", "-RTMIN+8", "waybar"], stderr=subprocess.DEVNULL)
    except Exception:
        pass


def apply_hw_settings(gov, epp, turbo, max_perf_pct, min_perf_pct):
    no_turbo = "0" if turbo else "1"
    # Ensure min <= max
    if min_perf_pct > max_perf_pct:
        min_perf_pct = max_perf_pct

    # Check if direct write is permitted
    direct = True
    for p in glob.glob("/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"):
        if not write_sysfs(p, gov):
            direct = False
            break

    if direct:
        for p in glob.glob("/sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference"):
            write_sysfs(p, epp)
        write_sysfs("/sys/devices/system/cpu/intel_pstate/no_turbo", no_turbo)
        write_sysfs("/sys/devices/system/cpu/intel_pstate/min_perf_pct", str(min_perf_pct))
        write_sysfs("/sys/devices/system/cpu/intel_pstate/max_perf_pct", str(max_perf_pct))
        write_sysfs("/sys/devices/system/cpu/intel_pstate/min_perf_pct", str(min_perf_pct))
    else:
        cmd = ["sudo", BACKEND_BIN, "apply", gov, epp, no_turbo, str(max_perf_pct), str(min_perf_pct)]
        subprocess.run(cmd, check=True)

    notify_waybar()


def set_profile(name):
    if name not in PROFILES:
        print(f"Unknown profile: {name}", file=sys.stderr)
        sys.exit(1)
    p = PROFILES[name]
    apply_hw_settings(p["governor"], p["epp"], p["turbo"], p["max_perf_pct"], p["min_perf_pct"])
    state = load_state()
    state["base_profile"] = name
    save_state(state)


def set_param(args):
    hw = get_hw_state()
    gov = args.governor or hw["governor"]
    epp = args.epp or hw["epp"]
    turbo = args.turbo if args.turbo is not None else hw["turbo"]
    max_perf_pct = args.max_perf_pct if args.max_perf_pct is not None else hw["max_perf_pct"]
    min_perf_pct = args.min_perf_pct if args.min_perf_pct is not None else hw["min_perf_pct"]

    apply_hw_settings(gov, epp, turbo, max_perf_pct, min_perf_pct)
    state = load_state()
    save_state(state)


def reset_to_base():
    state = load_state()
    base = state.get("base_profile", "balanced")
    set_profile(base)


def pct_to_freq_label(pct):
    if pct <= 8:
        return "400 MHz"
    mhz = int(round((pct / 100.0) * 4700))
    if mhz < 1000:
        return f"{mhz} MHz"
    else:
        return f"{mhz / 1000.0:.1f} GHz"


def get_full_status():
    hw = get_hw_state()
    state = load_state()
    base = state.get("base_profile", "balanced")
    current_key = match_profile(hw)

    if current_key == "custom":
        base_name = PROFILES.get(base, {}).get("name", "Balanced")
        display_name = f"Custom (from {base_name})"
        glyph = "󰒓"
        short = "Cust"
    else:
        p = PROFILES[current_key]
        display_name = p["name"]
        glyph = p["glyph"]
        short = p["short"]

    return {
        "base_profile": base,
        "active_profile": current_key,
        "display_name": display_name,
        "glyph": glyph,
        "short": short,
        "governor": hw["governor"],
        "epp": hw["epp"],
        "turbo": hw["turbo"],
        "min_perf_pct": hw["min_perf_pct"],
        "max_perf_pct": hw["max_perf_pct"],
        "avg_freq_ghz": hw["avg_freq_ghz"],
        "temp_c": hw["temp_c"],
    }


def print_waybar():
    st = get_full_status()
    text = f"{st['glyph']}  {st['short']}"
    turbo_str = "ON" if st["turbo"] else "OFF"
    min_str = pct_to_freq_label(st['min_perf_pct'])
    max_str = pct_to_freq_label(st['max_perf_pct'])
    tooltip = (
        f"Profile: {st['display_name']}\n"
        f"Governor: {st['governor']}  |  EPP: {st['epp']}\n"
        f"Limits: {min_str} – {max_str} (Turbo: {turbo_str})\n"
        f"CPU: {st['avg_freq_ghz']:.2f} GHz  |  Temp: {st['temp_c']}°C"
    )
    out = {
        "text": text,
        "alt": st["active_profile"],
        "tooltip": tooltip,
        "class": st["active_profile"],
    }
    print(json.dumps(out))


def main():
    parser = argparse.ArgumentParser(description="Power Profile Controller")
    subparsers = parser.add_subparsers(dest="command")

    # set-profile
    sp_prof = subparsers.add_parser("set-profile")
    sp_prof.add_argument("name", choices=["performance", "balanced", "powersaver"])

    # set-param
    sp_param = subparsers.add_parser("set-param")
    sp_param.add_argument("--governor", choices=["performance", "powersave"])
    sp_param.add_argument("--epp", choices=["performance", "balance_performance", "balance_power", "power"])
    sp_param.add_argument("--turbo", type=lambda x: x.lower() in ("1", "true", "yes", "on"))
    sp_param.add_argument("--min-perf-pct", type=int)
    sp_param.add_argument("--max-perf-pct", type=int)

    # reset
    subparsers.add_parser("reset")

    # get-json
    subparsers.add_parser("get-json")

    # waybar
    subparsers.add_parser("waybar")

    # is <profile>
    sp_is = subparsers.add_parser("is")
    sp_is.add_argument("name", choices=["performance", "balanced", "powersaver", "custom"])

    args = parser.parse_args()

    if args.command == "set-profile":
        set_profile(args.name)
    elif args.command == "set-param":
        set_param(args)
    elif args.command == "reset":
        reset_to_base()
    elif args.command == "get-json":
        print(json.dumps(get_full_status(), indent=2))
    elif args.command == "waybar":
        print_waybar()
    elif args.command == "is":
        st = get_full_status()
        if st["active_profile"] == args.name:
            sys.exit(0)
        else:
            sys.exit(1)
    else:
        print_waybar()


if __name__ == "__main__":
    main()
