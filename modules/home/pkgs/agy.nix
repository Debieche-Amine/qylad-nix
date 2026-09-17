{
  config,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;

  agy2 = pkgs.writeShellScriptBin "agy2" ''
    export HOME=${homeDir}/.homes/home2
    export XDG_CONFIG_HOME="$HOME/config"
    export XDG_DATA_HOME="$HOME/data"
    export XDG_CACHE_HOME="$HOME/cache"
    export XDG_RUNTIME_DIR=/tmp/agy2-runtime
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/nonexistent-dbus-socket"

    mkdir -p \
      "$HOME" \
      "$XDG_CONFIG_HOME" \
      "$XDG_DATA_HOME" \
      "$XDG_CACHE_HOME" \
      "$XDG_RUNTIME_DIR"

    chmod 700 "$XDG_RUNTIME_DIR"

    exec ${pkgs.unstable.antigravity-cli}/bin/agy "$@"
  '';

  agy3 = pkgs.writeShellScriptBin "agy3" ''
    export HOME=${homeDir}/.homes/home3
    export XDG_CONFIG_HOME="$HOME/config"
    export XDG_DATA_HOME="$HOME/data"
    export XDG_CACHE_HOME="$HOME/cache"
    export XDG_RUNTIME_DIR=/tmp/agy3-runtime
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/nonexistent-dbus-socket"

    mkdir -p \
      "$HOME" \
      "$XDG_CONFIG_HOME" \
      "$XDG_DATA_HOME" \
      "$XDG_CACHE_HOME" \
      "$XDG_RUNTIME_DIR"

    chmod 700 "$XDG_RUNTIME_DIR"

    exec ${pkgs.unstable.antigravity-cli}/bin/agy "$@"
  '';

  agy4 = pkgs.writeShellScriptBin "agy4" ''
    export HOME=${homeDir}/.homes/home4
    export XDG_CONFIG_HOME="$HOME/config"
    export XDG_DATA_HOME="$HOME/data"
    export XDG_CACHE_HOME="$HOME/cache"
    export XDG_RUNTIME_DIR=/tmp/agy4-runtime
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/nonexistent-dbus-socket"

    mkdir -p \
      "$HOME" \
      "$XDG_CONFIG_HOME" \
      "$XDG_DATA_HOME" \
      "$XDG_CACHE_HOME" \
      "$XDG_RUNTIME_DIR"

    chmod 700 "$XDG_RUNTIME_DIR"

    exec ${pkgs.unstable.antigravity-cli}/bin/agy "$@"
  '';

  agy5 = pkgs.writeShellScriptBin "agy5" ''
    export HOME=${homeDir}/.homes/home5
    export XDG_CONFIG_HOME="$HOME/config"
    export XDG_DATA_HOME="$HOME/data"
    export XDG_CACHE_HOME="$HOME/cache"
    export XDG_RUNTIME_DIR=/tmp/agy5-runtime
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/nonexistent-dbus-socket"

    mkdir -p \
      "$HOME" \
      "$XDG_CONFIG_HOME" \
      "$XDG_DATA_HOME" \
      "$XDG_CACHE_HOME" \
      "$XDG_RUNTIME_DIR"

    chmod 700 "$XDG_RUNTIME_DIR"

    exec ${pkgs.master.antigravity-cli}/bin/agy "$@"
  '';

  agy6 = pkgs.writeShellScriptBin "agy6" ''
    export HOME=${homeDir}/.homes/home6
    export XDG_CONFIG_HOME="$HOME/config"
    export XDG_DATA_HOME="$HOME/data"
    export XDG_CACHE_HOME="$HOME/cache"
    export XDG_RUNTIME_DIR=/tmp/agy6-runtime
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/nonexistent-dbus-socket"

    mkdir -p \
      "$HOME" \
      "$XDG_CONFIG_HOME" \
      "$XDG_DATA_HOME" \
      "$XDG_CACHE_HOME" \
      "$XDG_RUNTIME_DIR"

    chmod 700 "$XDG_RUNTIME_DIR"

    exec ${pkgs.unstable.antigravity-cli}/bin/agy "$@"
  '';

  agy7 = pkgs.writeShellScriptBin "agy7" ''
    export HOME=${homeDir}/.homes/home7
    export XDG_CONFIG_HOME="$HOME/config"
    export XDG_DATA_HOME="$HOME/data"
    export XDG_CACHE_HOME="$HOME/cache"
    export XDG_RUNTIME_DIR=/tmp/agy7-runtime
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/nonexistent-dbus-socket"

    mkdir -p \
      "$HOME" \
      "$XDG_CONFIG_HOME" \
      "$XDG_DATA_HOME" \
      "$XDG_CACHE_HOME" \
      "$XDG_RUNTIME_DIR"

    chmod 700 "$XDG_RUNTIME_DIR"

    exec ${pkgs.unstable.antigravity-cli}/bin/agy "$@"
  '';

  agy8 = pkgs.writeShellScriptBin "agy8" ''
    export HOME=${homeDir}/.homes/home8
    export XDG_CONFIG_HOME="$HOME/config"
    export XDG_DATA_HOME="$HOME/data"
    export XDG_CACHE_HOME="$HOME/cache"
    export XDG_RUNTIME_DIR=/tmp/agy8-runtime
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/nonexistent-dbus-socket"

    mkdir -p \
      "$HOME" \
      "$XDG_CONFIG_HOME" \
      "$XDG_DATA_HOME" \
      "$XDG_CACHE_HOME" \
      "$XDG_RUNTIME_DIR"

    chmod 700 "$XDG_RUNTIME_DIR"

    exec ${pkgs.unstable.antigravity-cli}/bin/agy "$@"
  '';

  agy9 = pkgs.writeShellScriptBin "agy9" ''
    export HOME=${homeDir}/.homes/home9
    export XDG_CONFIG_HOME="$HOME/config"
    export XDG_DATA_HOME="$HOME/data"
    export XDG_CACHE_HOME="$HOME/cache"
    export XDG_RUNTIME_DIR=/tmp/agy9-runtime
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/nonexistent-dbus-socket"

    mkdir -p \
      "$HOME" \
      "$XDG_CONFIG_HOME" \
      "$XDG_DATA_HOME" \
      "$XDG_CACHE_HOME" \
      "$XDG_RUNTIME_DIR"

    chmod 700 "$XDG_RUNTIME_DIR"

    exec ${pkgs.unstable.antigravity-cli}/bin/agy "$@"
  '';

  agy10 = pkgs.writeShellScriptBin "agy10" ''
    export HOME=${homeDir}/.homes/home10
    export XDG_CONFIG_HOME="$HOME/config"
    export XDG_DATA_HOME="$HOME/data"
    export XDG_CACHE_HOME="$HOME/cache"
    export XDG_RUNTIME_DIR=/tmp/agy10-runtime
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/nonexistent-dbus-socket"

    mkdir -p \
      "$HOME" \
      "$XDG_CONFIG_HOME" \
      "$XDG_DATA_HOME" \
      "$XDG_CACHE_HOME" \
      "$XDG_RUNTIME_DIR"

    chmod 700 "$XDG_RUNTIME_DIR"

    exec ${pkgs.unstable.antigravity-cli}/bin/agy "$@"
  '';

  agy-usage = pkgs.writeShellScriptBin "agy-usage" ''
        exec ${pkgs.python3}/bin/python3 - "$@" << 'PYEOF'
    import os
    import sys
    import json
    import re
    import subprocess
    import urllib.request
    from datetime import datetime, timezone
    from concurrent.futures import ThreadPoolExecutor

    args = sys.argv[1:]
    if "-h" in args or "--help" in args:
        print("Usage: agy-usage [options]")
        print("")
        print("Options:")
        print("  -e, --email    Show email address associated with each account")
        print("  --json         Output account usage data in JSON format")
        print("  -h, --help     Show this help message")
        sys.exit(0)

    show_email = "-e" in args or "--email" in args
    json_mode = "--json" in args

    is_tty = sys.stdout.isatty() or os.environ.get("FORCE_COLOR") == "1"
    if os.environ.get("NO_COLOR") == "1":
        is_tty = False

    def c(text, color_name):
        if not is_tty:
            return text
        colors = {
            "reset": "\033[0m",
            "bold": "\033[1m",
            "dim": "\033[2m",
            "gray": "\033[90m",
            "cyan": "\033[36m",
            "green": "\033[32m",
            "yellow": "\033[33m",
            "red": "\033[31m",
            "bright_green": "\033[92m",
            "bright_yellow": "\033[93m",
            "bright_red": "\033[91m",
            "bright_cyan": "\033[96m",
        }
        code = colors.get(color_name, "")
        rst = colors["reset"]
        return f"{code}{text}{rst}"

    def render_bar(fraction, width=10):
        if fraction is None:
            return " " * width
        filled = int(round(fraction * width))
        filled = max(0, min(width, filled))
        empty = width - filled

        if fraction >= 0.5:
            bar_color = "bright_green"
        elif fraction >= 0.2:
            bar_color = "bright_yellow"
        else:
            bar_color = "bright_red"

        return c("█" * filled, bar_color) + c("░" * empty, "gray")

    def format_time_left(reset_time_str, desc, fraction):
        if fraction is not None and fraction >= 0.999:
            return c("ready", "dim"), 5

        if reset_time_str:
            try:
                rt = datetime.fromisoformat(reset_time_str.replace("Z", "+00:00"))
                now = datetime.now(timezone.utc)
                diff = rt - now
                tot_sec = int(diff.total_seconds())
                if tot_sec <= 0:
                    return c("ready", "dim"), 5
                days = diff.days
                hours = (diff.seconds // 3600)
                minutes = (diff.seconds % 3600) // 60
                if days > 0:
                    txt = f"{days}d {hours:02d}h"
                    return txt, len(txt)
                elif hours > 0:
                    txt = f"{hours}h {minutes:02d}m"
                    return txt, len(txt)
                else:
                    txt = f"{minutes}m"
                    return txt, len(txt)
            except Exception:
                pass

        if desc:
            m = re.search(r"refresh(?:es)? in ([\d\w\s,]+?)(?:\.|$)", desc)
            if m:
                t = m.group(1).strip()
                t = re.sub(r"(\d+)\s*days?", r"\1d", t)
                t = re.sub(r"(\d+)\s*hours?", r"\1h", t)
                t = re.sub(r"(\d+)\s*minutes?", r"\1m", t)
                t = t.replace(",", " ").replace("  ", " ")
                t = t[:6].strip()
                return t, len(t)
        return "-", 1

    def get_account_email(hdir):
        cache_file = os.path.join(hdir, ".gemini", "antigravity-cli", ".cached_email")
        if os.path.exists(cache_file):
            try:
                with open(cache_file, "r") as f:
                    em = f.read().strip()
                    if em:
                        return em
            except Exception:
                pass
        tok_file = os.path.join(hdir, ".gemini", "antigravity-cli", "antigravity-oauth-token")
        if not os.path.exists(tok_file):
            return None
        try:
            with open(tok_file, "r") as f:
                token = json.load(f).get("token", {}).get("access_token")
            if not token:
                return None
            req = urllib.request.Request(f"https://oauth2.googleapis.com/tokeninfo?access_token={token}")
            with urllib.request.urlopen(req, timeout=5) as resp:
                tinfo = json.loads(resp.read().decode())
                email = tinfo.get("email")
                if email:
                    try:
                        with open(cache_file, "w") as f:
                            f.write(email)
                    except Exception:
                        pass
                    return email
        except Exception:
            return None
        return None

    def check_account(item):
        name, cmd, hdir = item
        token_path = os.path.join(hdir, ".gemini", "antigravity-cli", "antigravity-oauth-token")
        if not os.path.exists(token_path):
            return {"name": name, "connected": False, "reason": "Not connected", "email": None}

        try:
            res = subprocess.run(
                [cmd, "-p", "/usage", "--output-format", "json"],
                stdin=subprocess.DEVNULL,
                capture_output=True, text=True, timeout=12
            )
            if "Authentication required" in res.stdout or "Authentication required" in res.stderr:
                return {"name": name, "connected": False, "reason": "Not connected", "email": None}
            if res.returncode != 0:
                return {"name": name, "connected": False, "reason": "Not connected", "email": None}

            data = json.loads(res.stdout)
            if data.get("status") != "SUCCESS":
                return {"name": name, "connected": False, "reason": "Not connected", "email": None}

            groups = data.get("command", {}).get("data", {}).get("groups", [])
            gemini = next((g for g in groups if g.get("name") == "Gemini Models"), None)
            if not gemini:
                return {"name": name, "connected": False, "reason": "No Gemini data", "email": None}

            buckets = gemini.get("buckets", [])
            w_b = next((b for b in buckets if b.get("id") == "gemini-weekly" or b.get("window") == "weekly"), {})
            h_b = next((b for b in buckets if b.get("id") == "gemini-5h" or b.get("window") == "5h"), {})

            email = None
            if show_email or json_mode:
                email = get_account_email(hdir)

            return {
                "name": name,
                "connected": True,
                "email": email,
                "weekly": {
                    "fraction": w_b.get("remaining_fraction"),
                    "disabled": w_b.get("disabled", False),
                    "reset_time": w_b.get("reset_time"),
                    "desc": w_b.get("description", "")
                },
                "five_hour": {
                    "fraction": h_b.get("remaining_fraction"),
                    "disabled": h_b.get("disabled", False),
                    "reset_time": h_b.get("reset_time"),
                    "desc": h_b.get("description", "")
                }
            }
        except Exception:
            return {"name": name, "connected": False, "reason": "Not connected", "email": None}

    default_home = os.environ.get("HOME", "${homeDir}")
    targets = [
        ("agy", "${pkgs.unstable.antigravity-cli}/bin/agy", default_home),
        ("agy2", "${agy2}/bin/agy2", "${homeDir}/.homes/home2"),
        ("agy3", "${agy3}/bin/agy3", "${homeDir}/.homes/home3"),
        ("agy4", "${agy4}/bin/agy4", "${homeDir}/.homes/home4"),
        ("agy5", "${agy5}/bin/agy5", "${homeDir}/.homes/home5"),
        ("agy6", "${agy6}/bin/agy6", "${homeDir}/.homes/home6"),
        ("agy7", "${agy7}/bin/agy7", "${homeDir}/.homes/home7"),
        ("agy8", "${agy8}/bin/agy8", "${homeDir}/.homes/home8"),
        ("agy9", "${agy9}/bin/agy9", "${homeDir}/.homes/home9"),
        ("agy10", "${agy10}/bin/agy10", "${homeDir}/.homes/home10"),
    ]

    with ThreadPoolExecutor(max_workers=10) as ex:
        results = list(ex.map(check_account, targets))

    if json_mode:
        out = []
        for r in results:
            item = {
                "account": r["name"],
                "connected": r["connected"]
            }
            if r["connected"]:
                item["email"] = r.get("email")
                w = r["weekly"]
                h = r["five_hour"]
                w_time, _ = format_time_left(w.get("reset_time"), w.get("desc"), w.get("fraction"))
                raw_w_time = re.sub(r"\033\[[0-9;]*m", "", w_time).strip()
                item["gemini_weekly"] = {
                    "remaining_fraction": w.get("fraction"),
                    "remaining_percentage": int(round(w["fraction"] * 100)) if w.get("fraction") is not None else None,
                    "reset_time": w.get("reset_time"),
                    "time_left": raw_w_time,
                    "disabled": w.get("disabled", False)
                }
                if h.get("disabled"):
                    raw_h_time = "paused"
                else:
                    h_time, _ = format_time_left(h.get("reset_time"), h.get("desc"), h.get("fraction"))
                    raw_h_time = re.sub(r"\033\[[0-9;]*m", "", h_time).strip()
                item["gemini_5h"] = {
                    "remaining_fraction": h.get("fraction"),
                    "remaining_percentage": None if h.get("disabled") else (int(round(h["fraction"] * 100)) if h.get("fraction") is not None else None),
                    "reset_time": h.get("reset_time"),
                    "time_left": raw_h_time,
                    "disabled": h.get("disabled", False)
                }
            else:
                item["email"] = None
                item["reason"] = r.get("reason", "Not connected")
            out.append(item)
        print(json.dumps(out, indent=2))
        sys.exit(0)

    W_ACC = 7
    W_DATA = 26
    W_BOTH = W_DATA + 3 + W_DATA

    dash_acc = "─" * W_ACC
    dash_data = "─" * W_DATA

    border_color = "gray"
    b = lambda text: c(text, border_color)

    acc_hdr = "Account"
    gw_hdr = "Gemini Weekly"
    g5_hdr = "Gemini 5-Hour"
    sp = " "

    print(b(f"╭─{dash_acc}─┬─{dash_data}─┬─{dash_data}─╮"))
    print(b("│ ") + c(f"{acc_hdr:<{W_ACC}}", "bold") + b(" │ ") +
          c(f"{gw_hdr:<{W_DATA}}", "bold") + b(" │ ") +
          c(f"{g5_hdr:<{W_DATA}}", "bold") + b(" │"))
    print(b(f"├─{dash_acc}─┼─{dash_data}─┼─{dash_data}─┤"))

    prev_connected = True
    for i, r in enumerate(results):
        name = r["name"]
        name_fmt = c(f"{name:<{W_ACC}}", "bright_cyan" if r["connected"] else "dim")

        if show_email and i > 0 and (r["connected"] or prev_connected):
            print(b(f"├─{dash_acc}─┼─{dash_data}─┼─{dash_data}─┤"))
        prev_connected = r["connected"]

        if not r["connected"]:
            msg = r["reason"]
            msg_len = len(msg)
            pad_l = (W_BOTH - msg_len) // 2
            pad_r = W_BOTH - msg_len - pad_l
            center_str = (" " * pad_l) + c(msg, "dim") + (" " * pad_r)
            print(b("│ ") + name_fmt + b(" │ ") + center_str + b(" │"))
        else:
            # Format Weekly
            w = r["weekly"]
            w_frac = w.get("fraction")
            w_bar = render_bar(w_frac)
            w_time, w_t_len = format_time_left(w.get("reset_time"), w.get("desc"), w_frac)
            if w_frac is not None:
                pct_val = int(round(w_frac * 100))
                color_pct = "bright_green" if pct_val >= 50 else ("bright_yellow" if pct_val >= 20 else "bright_red")
                pct_str = c(f"{pct_val:>3}%", color_pct)
            else:
                pct_str = c(" --%", "dim")
            time_pad = 7 - w_t_len
            w_col = f" {pct_str}  {w_bar}  {w_time}" + (" " * max(0, time_pad))

            # Format 5h
            h = r["five_hour"]
            if h.get("disabled"):
                h_bar = c("░" * 10, "gray")
                h_time = c("paused", "dim")
                dash_pct = c(" --%", "dim")
                h_col = f" {dash_pct}  {h_bar}  {h_time} "
            else:
                h_frac = h.get("fraction")
                h_bar = render_bar(h_frac)
                h_time, h_t_len = format_time_left(h.get("reset_time"), h.get("desc"), h_frac)
                if h_frac is not None:
                    pct_val = int(round(h_frac * 100))
                    color_pct = "bright_green" if pct_val >= 50 else ("bright_yellow" if pct_val >= 20 else "bright_red")
                    pct_str = c(f"{pct_val:>3}%", color_pct)
                else:
                    pct_str = c(" --%", "dim")
                time_pad = 7 - h_t_len
                h_col = f" {pct_str}  {h_bar}  {h_time}" + (" " * max(0, time_pad))

            print(b("│ ") + name_fmt + b(" │ ") + w_col + b(" │ ") + h_col + b(" │"))

            if show_email:
                em = r.get("email") or "(no email found)"
                sub = f"↳ {em}"
                sub_pad = W_BOTH - len(sub)
                sub_str = c(sub, "dim") + (" " * max(0, sub_pad))
                print(b("│ ") + f"{sp:<{W_ACC}}" + b(" │ ") + sub_str + b(" │"))

    print(b(f"╰─{dash_acc}─┴─{dash_data}─┴─{dash_data}─╯"))
    PYEOF
  '';
in {
  home.packages = [
    pkgs.unstable.antigravity-cli
    agy2
    agy3
    agy4
    agy5
    agy6
    agy7
    agy8
    agy9
    agy10
    agy-usage
  ];
}
