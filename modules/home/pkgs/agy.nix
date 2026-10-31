{
  config,
  pkgs,
  inputs ? null,
  ...
}: let
  homeDir = config.home.homeDirectory;

  playwrightPkg =
    if inputs != null && inputs ? mcp-servers-nix && inputs.mcp-servers-nix ? packages && inputs.mcp-servers-nix.packages ? ${pkgs.system} && inputs.mcp-servers-nix.packages.${pkgs.system} ? playwright-mcp
    then inputs.mcp-servers-nix.packages.${pkgs.system}.playwright-mcp
    else null;

  mcpConfig = {
    mcpServers = {
      playwright = {
        command =
          if playwrightPkg != null
          then "${playwrightPkg}/bin/playwright-mcp"
          else "nix";
        args =
          if playwrightPkg != null
          then [
            "--browser"
            "chromium"
            "--executable-path"
            "${pkgs.chromium}/bin/chromium"
          ]
          else [
            "run"
            "github:natsukium/mcp-servers-nix#playwright-mcp"
            "--"
            "--browser"
            "chromium"
            "--executable-path"
            "${pkgs.chromium}/bin/chromium"
          ];
      };
      nixos = {
        command = "nix";
        args = [
          "run"
          "github:utensils/mcp-nixos"
          "--"
        ];
      };
    };
  };

  antigravityCli = pkgs.symlinkJoin {
    name = "antigravity-cli";
    paths = [pkgs.unstable.antigravity-cli];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/agy \
        --set DBUS_SESSION_BUS_ADDRESS "unix:path=/tmp/nonexistent-dbus-socket" \
        --set DO_NOT_TRACK "1" \
        --set GEMINI_TELEMETRY_ENABLED "false"
    '';
  };

  antigravitySettings = {
    artifactReviewPolicy = "agent-decides";
    editorMode = "vim";
    vimInsertFirst = true;
    model = "Gemini 3.8 Flash (High)";
    showFeedbackSurvey = false;
    enableTelemetry = false;
    statusLine = {
      type = "";
      command = "";
      enabled = false;
    };
    toolPermission = "always-proceed";
    trustedWorkspaces = [
      homeDir
      "${homeDir}/nixos"
      "${homeDir}/project"
      "${homeDir}/ram"
      "/tmp"
    ];
  };

  agyn = pkgs.writeShellScriptBin "agyn" ''
            set -euo pipefail

            if [ $# -lt 1 ]; then
              echo "Usage: agyn <account_id> [agy args...]" >&2
              echo "Example: agyn 2 -p 'hello'" >&2
              exit 1
            fi

            ACCOUNT_ID="$1"
            shift

            REAL_HOME="$HOME"
            if [[ "$REAL_HOME" =~ (.*)/\.gemini/accounts/ ]]; then
              REAL_HOME="''${BASH_REMATCH[1]}"
            fi

            ACCOUNT_DIR="$REAL_HOME/.gemini/accounts/$ACCOUNT_ID"
            TOKEN_FILE="$ACCOUNT_DIR/antigravity-oauth-token"
            PROFILE_HOME="$ACCOUNT_DIR/profile"
            PROFILE_CLI="$PROFILE_HOME/.gemini/antigravity-cli"

            mkdir -p "$ACCOUNT_DIR" "$PROFILE_CLI/cache" "$PROFILE_HOME/.gemini/config" "$PROFILE_HOME/.config" "$PROFILE_HOME/.local/share"

            ln -sf "$REAL_HOME/.gemini/antigravity-cli/settings.json" "$PROFILE_CLI/settings.json"
            ln -sf "$REAL_HOME/.gemini/antigravity-cli/cache/onboarding.json" "$PROFILE_CLI/cache/onboarding.json"
            ln -sf "$REAL_HOME/.gemini/antigravity-cli/jetski_state.pbtxt" "$PROFILE_CLI/jetski_state.pbtxt"
            ln -sf "$REAL_HOME/.gemini/settings.json" "$PROFILE_HOME/.gemini/settings.json"
            ln -sf "$REAL_HOME/.gemini/config/mcp_config.json" "$PROFILE_HOME/.gemini/config/mcp_config.json"

            if [ -f "$TOKEN_FILE" ]; then
              if [ ! -f "$PROFILE_CLI/antigravity-oauth-token" ] || [ "$TOKEN_FILE" -nt "$PROFILE_CLI/antigravity-oauth-token" ]; then
                cp -f "$TOKEN_FILE" "$PROFILE_CLI/antigravity-oauth-token"
                chmod 600 "$PROFILE_CLI/antigravity-oauth-token"
              elif [ "$PROFILE_CLI/antigravity-oauth-token" -nt "$TOKEN_FILE" ]; then
                cp -f "$PROFILE_CLI/antigravity-oauth-token" "$TOKEN_FILE"
                chmod 600 "$TOKEN_FILE"
              fi
            elif [ -f "$PROFILE_CLI/antigravity-oauth-token" ]; then
              cp -f "$PROFILE_CLI/antigravity-oauth-token" "$TOKEN_FILE"
              chmod 600 "$TOKEN_FILE"
            fi

            if [ -f "$ACCOUNT_DIR/email" ]; then
              cp -f "$ACCOUNT_DIR/email" "$PROFILE_CLI/.cached_email"
            elif [ -f "$PROFILE_CLI/.cached_email" ]; then
              cp -f "$PROFILE_CLI/.cached_email" "$ACCOUNT_DIR/email"
            fi

            cleanup() {
              if [ -f "$PROFILE_CLI/antigravity-oauth-token" ]; then
                if [ ! -f "$TOKEN_FILE" ] || [ "$PROFILE_CLI/antigravity-oauth-token" -nt "$TOKEN_FILE" ]; then
                  cp -f "$PROFILE_CLI/antigravity-oauth-token" "$TOKEN_FILE"
                  chmod 600 "$TOKEN_FILE"
                fi
              elif [ -f "$TOKEN_FILE" ]; then
                cp -f "$TOKEN_FILE" "$PROFILE_CLI/antigravity-oauth-token"
                chmod 600 "$PROFILE_CLI/antigravity-oauth-token"
              fi

              if [ -f "$TOKEN_FILE" ]; then
                local email=""
                if [ -f "$ACCOUNT_DIR/email" ] && [ -s "$ACCOUNT_DIR/email" ]; then
                  email=$(cat "$ACCOUNT_DIR/email" | tr -d '[:space:]')
                fi
                if [ -z "$email" ]; then
                  email=$(${pkgs.python3}/bin/python3 - "$TOKEN_FILE" << 'PYEOF' 2>/dev/null || true
    import sys, json, base64
    try:
        with open(sys.argv[1]) as f:
            data = json.load(f)
        id_tok = data.get("id_token", "")
        if id_tok and "." in id_tok:
            payload = id_tok.split(".")[1]
            payload += "=" * (-len(payload) % 4)
            claims = json.loads(base64.urlsafe_b64decode(payload))
            print(claims.get("email", ""))
    except Exception:
        pass
    PYEOF
    )
                  if [ -n "$email" ]; then
                    echo "$email" > "$ACCOUNT_DIR/email"
                  fi
                fi
                if [ -n "$email" ]; then
                  cp -f "$ACCOUNT_DIR/email" "$PROFILE_CLI/.cached_email"
                fi
              fi
            }
            trap cleanup EXIT INT TERM

            echo "$ACCOUNT_ID" > "$REAL_HOME/.gemini/accounts/.current" 2>/dev/null || true

            export HOME="$PROFILE_HOME"
            export XDG_CONFIG_HOME="$PROFILE_HOME/.config"
            export XDG_DATA_HOME="$PROFILE_HOME/.local/share"
            if [ -n "''${AGYN_CACHE_DIR:-}" ]; then
              export XDG_CACHE_HOME="$AGYN_CACHE_DIR"
            else
              export XDG_CACHE_HOME="/tmp/agy-cache-$ACCOUNT_ID"
            fi
            export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/nonexistent-dbus-socket"
            export DO_NOT_TRACK="1"
            export GEMINI_TELEMETRY_ENABLED="false"
            export GOPATH="$REAL_HOME/go"
            export CARGO_HOME="$REAL_HOME/.cargo"
            export RUSTUP_HOME="$REAL_HOME/.rustup"

            "${antigravityCli}/bin/agy" "$@"
  '';

  mkAgyWrapper = id:
    pkgs.writeShellScriptBin "agy${toString id}" ''
      exec ${agyn}/bin/agyn ${toString id} "$@"
    '';
  agyWrappers = map mkAgyWrapper (pkgs.lib.range 1 40);

  # agy-usage: Parallel account usage checker querying ~/.gemini/accounts
  agy-usage = pkgs.writeShellScriptBin "agy-usage" ''
    exec ${pkgs.python3}/bin/python3 - "$@" << 'PYEOF'
    import os
    import sys
    import json
    import re
    import signal
    import subprocess
    import threading
    import shutil
    import base64
    import time
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

    home_dir = os.path.expanduser("~")
    m = re.match(r"^(.*?)/\.gemini/accounts/", home_dir)
    real_home = m.group(1) if m else home_dir
    accounts_dir = os.path.join(real_home, ".gemini", "accounts")
    current_file = os.path.join(accounts_dir, ".current")
    current_id = None
    if os.path.exists(current_file):
        try:
            with open(current_file) as f:
                current_id = f.read().strip()
        except Exception:
            pass

    account_ids = []
    if os.path.isdir(accounts_dir):
        for entry in os.listdir(accounts_dir):
            if os.path.isdir(os.path.join(accounts_dir, entry)) and not entry.startswith('.'):
                account_ids.append(entry)
    account_ids.sort(key=lambda x: (0, int(x)) if x.isdigit() else (1, str(x)))

    if not account_ids:
        if json_mode:
            print("[]")
        else:
            print(f"No accounts found in {accounts_dir}")
        sys.exit(0)

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
        return colors.get(color_name, "") + text + colors["reset"]

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

    def format_row(r):
        name = r["name"]
        is_cur = r.get("is_current", False)
        display_name = f"*{name}" if is_cur else name
        name_fmt = c(f"{display_name:<{W_ACC}}", "bright_cyan" if r["connected"] else "dim")

        if not r["connected"]:
            msg = r["reason"]
            msg_len = len(msg)
            pad_l = max(0, (W_BOTH - msg_len) // 2)
            pad_r = max(0, W_BOTH - msg_len - pad_l)
            if "retry" in msg.lower() or "timed out" in msg.lower() or "verify" in msg.lower():
                color_reason = "bright_yellow"
            elif "expired" in msg.lower() or "no token" in msg.lower():
                color_reason = "bright_red"
            else:
                color_reason = "dim"
            center_str = (" " * pad_l) + c(msg, color_reason) + (" " * pad_r)
            return b("│ ") + name_fmt + b(" │ ") + center_str + b(" │")
        else:
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

            return b("│ ") + name_fmt + b(" │ ") + w_col + b(" │ ") + h_col + b(" │")

    def format_email_row(email):
        em = email or "(no email found)"
        sub = f"↳ {em}"
        sub_pad = W_BOTH - len(sub)
        sub_str = c(sub, "dim") + (" " * max(0, sub_pad))
        return b("│ ") + f"{sp:<{W_ACC}}" + b(" │ ") + sub_str + b(" │")

    active_procs = set()
    active_procs_lock = threading.Lock()

    def sig_handler(sig, frame):
        with active_procs_lock:
            for p in list(active_procs):
                try:
                    p.kill()
                except Exception:
                    pass
        sys.exit(130)

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    def check_single_account(acc_id, update_slot_cb):
        acc_path = os.path.join(accounts_dir, acc_id)
        tok_file = os.path.join(acc_path, "antigravity-oauth-token")
        email_file = os.path.join(acc_path, "email")
        if not os.path.exists(tok_file):
            res = {"name": acc_id, "is_current": (acc_id == current_id), "connected": False, "reason": "No token", "email": None}
            update_slot_cb(acc_id, res)
            return res

        email = None
        if os.path.exists(email_file):
            try:
                with open(email_file) as f:
                    email = f.read().strip()
            except Exception:
                pass
        if not email:
            try:
                with open(tok_file) as f:
                    tok_data = json.load(f)
                id_tok = tok_data.get("id_token", "")
                if id_tok and "." in id_tok:
                    payload = id_tok.split(".")[1]
                    payload += "=" * (-len(payload) % 4)
                    claims = json.loads(base64.urlsafe_b64decode(payload))
                    email = claims.get("email")
                    if email:
                        with open(email_file, "w") as ef:
                            ef.write(email)
            except Exception:
                pass

        profile_home = os.path.join(acc_path, "profile")
        profile_cli = os.path.join(profile_home, ".gemini", "antigravity-cli")
        profile_token = os.path.join(profile_cli, "antigravity-oauth-token")
        cache_dir = f"/tmp/agy-cache-{acc_id}"

        try:
            os.makedirs(os.path.join(profile_cli, "cache"), exist_ok=True)
            os.makedirs(os.path.join(profile_home, ".gemini", "config"), exist_ok=True)
            os.makedirs(os.path.join(profile_home, ".config"), exist_ok=True)
            os.makedirs(os.path.join(profile_home, ".local", "share"), exist_ok=True)

            for fn in ["settings.json", "jetski_state.pbtxt"]:
                src = os.path.join(real_home, ".gemini", "antigravity-cli", fn)
                dst = os.path.join(profile_cli, fn)
                if os.path.exists(src) and not os.path.exists(dst):
                    try:
                        os.symlink(src, dst)
                    except Exception:
                        pass

            ob_src = os.path.join(real_home, ".gemini", "antigravity-cli", "cache", "onboarding.json")
            ob_dst = os.path.join(profile_cli, "cache", "onboarding.json")
            if os.path.exists(ob_src) and not os.path.exists(ob_dst):
                try:
                    os.symlink(ob_src, ob_dst)
                except Exception:
                    pass

            for src_rel, dst_rel in [
                (".gemini/settings.json", ".gemini/settings.json"),
                (".gemini/config/mcp_config.json", ".gemini/config/mcp_config.json")
            ]:
                s = os.path.join(real_home, src_rel)
                d = os.path.join(profile_home, dst_rel)
                if os.path.exists(s) and not os.path.exists(d):
                    try:
                        os.symlink(s, d)
                    except Exception:
                        pass

            if not os.path.exists(profile_token) or (os.path.exists(tok_file) and os.path.getmtime(tok_file) > os.path.getmtime(profile_token)):
                shutil.copyfile(tok_file, profile_token)
                os.chmod(profile_token, 0o600)
        except Exception:
            pass

        env = dict(
            os.environ,
            HOME=profile_home,
            XDG_CONFIG_HOME=os.path.join(profile_home, ".config"),
            XDG_DATA_HOME=os.path.join(profile_home, ".local", "share"),
            XDG_CACHE_HOME=cache_dir,
            DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/nonexistent-dbus-socket",
            DO_NOT_TRACK="1",
            GEMINI_TELEMETRY_ENABLED="false",
        )

        try:
            proc = subprocess.Popen(
                ["${antigravityCli}/bin/agy", "-p", "/usage", "--output-format", "json"],
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env, stdin=subprocess.DEVNULL
            )
            with active_procs_lock:
                active_procs.add(proc)
        except Exception:
            res = {"name": acc_id, "is_current": (acc_id == current_id), "connected": False, "reason": "Failed to run", "email": email}
            update_slot_cb(acc_id, res)
            return res

        lines = []
        perm_err = []

        def reader():
            for line in iter(proc.stdout.readline, ""):
                low = line.lower()
                if "authentication required" in low or "visit the url" in low or "invalid_grant" in low or "revoked" in low:
                    perm_err.append("Auth expired")
                    try:
                        proc.kill()
                    except Exception:
                        pass
                    break
                if "eligibility check failed" in low or "verify your account" in low:
                    perm_err.append("Verify in browser")
                    try:
                        proc.kill()
                    except Exception:
                        pass
                    break
                if "rate limit" in low or "resource has been exhausted" in low or "429" in low:
                    perm_err.append("Rate limited")
                    try:
                        proc.kill()
                    except Exception:
                        pass
                    break
                lines.append(line)

        t_reader = threading.Thread(target=reader, daemon=True)
        t_reader.start()

        try:
            proc.wait(timeout=60)
            t_reader.join(timeout=2)
        except subprocess.TimeoutExpired:
            try:
                proc.kill()
            except Exception:
                pass
            perm_err.append("Timed out")
        finally:
            with active_procs_lock:
                active_procs.discard(proc)

        if perm_err:
            res = {"name": acc_id, "is_current": (acc_id == current_id), "connected": False, "reason": perm_err[0], "email": email}
            update_slot_cb(acc_id, res)
            return res

        # Sync back token if refreshed by agy
        if os.path.exists(profile_token) and os.path.exists(tok_file):
            try:
                if os.path.getmtime(profile_token) > os.path.getmtime(tok_file):
                    shutil.copyfile(profile_token, tok_file)
                    os.chmod(tok_file, 0o600)
            except Exception:
                pass

        out_text = "".join(lines).strip()
        try:
            data = json.loads(out_text)
            if data.get("status") == "SUCCESS":
                groups = data.get("command", {}).get("data", {}).get("groups", [])
                gemini = next((g for g in groups if g.get("name") == "Gemini Models"), None)
                if not gemini:
                    res = {"name": acc_id, "is_current": (acc_id == current_id), "connected": False, "reason": "No Gemini data", "email": email}
                else:
                    buckets = gemini.get("buckets", [])
                    w_b = next((b for b in buckets if b.get("id") == "gemini-weekly" or b.get("window") == "weekly"), {})
                    h_b = next((b for b in buckets if b.get("id") == "gemini-5h" or b.get("window") == "5h"), {})
                    res = {
                        "name": acc_id,
                        "is_current": (acc_id == current_id),
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
            else:
                res = {"name": acc_id, "is_current": (acc_id == current_id), "connected": False, "reason": "Not connected", "email": email}
        except Exception:
            res = {"name": acc_id, "is_current": (acc_id == current_id), "connected": False, "reason": "Bad JSON", "email": email}

        update_slot_cb(acc_id, res)
        return res

    row_map = {}
    email_map = {}
    layout = []

    layout.append(b(f"╭─{dash_acc}─┬─{dash_data}─┬─{dash_data}─╮"))
    layout.append(b("│ ") + c(f"{acc_hdr:<{W_ACC}}", "bold") + b(" │ ") +
                  c(f"{gw_hdr:<{W_DATA}}", "bold") + b(" │ ") +
                  c(f"{g5_hdr:<{W_DATA}}", "bold") + b(" │"))
    layout.append(b(f"├─{dash_acc}─┼─{dash_data}─┼─{dash_data}─┤"))

    for i, acc_id in enumerate(account_ids):
        if show_email and i > 0:
            layout.append(b(f"├─{dash_acc}─┼─{dash_data}─┼─{dash_data}─┤"))
        row_map[acc_id] = len(layout)
        is_cur = (acc_id == current_id)
        d_name = f"*{acc_id}" if is_cur else acc_id
        n_fmt = c(f"{d_name:<{W_ACC}}", "dim")
        loading_msg = c("loading...", "dim")
        pad_l = (W_BOTH - 10) // 2
        pad_r = W_BOTH - 10 - pad_l
        holder = (" " * pad_l) + loading_msg + (" " * pad_r)
        layout.append(b("│ ") + n_fmt + b(" │ ") + holder + b(" │"))
        if show_email:
            email_map[acc_id] = len(layout)
            layout.append(format_email_row(None))

    layout.append(b(f"╰─{dash_acc}─┴─{dash_data}─┴─{dash_data}─╯"))
    total_lines = len(layout)

    print_lock = threading.Lock()
    results_dict = {}

    def update_slot(acc_id, r):
        results_dict[acc_id] = r
        if not is_tty or json_mode:
            return
        with print_lock:
            row_idx = row_map[acc_id]
            lines_up = total_lines - row_idx
            row_str = format_row(r)
            sys.stdout.write(f"\033[{lines_up}A\r\033[2K{row_str}\033[{lines_up}B\r")
            if show_email and acc_id in email_map and r.get("email"):
                em_idx = email_map[acc_id]
                em_up = total_lines - em_idx
                em_str = format_email_row(r.get("email"))
                sys.stdout.write(f"\033[{em_up}A\r\033[2K{em_str}\033[{em_up}B\r")
            sys.stdout.flush()

    if is_tty and not json_mode:
        sys.stdout.write("\n" * total_lines)
        sys.stdout.write(f"\033[{total_lines}A\r")
        for line in layout:
            sys.stdout.write(line + "\n")
        sys.stdout.flush()

    num_workers = min(len(account_ids), 5)
    with ThreadPoolExecutor(max_workers=num_workers) as ex:
        futures = [ex.submit(check_single_account, aid, update_slot) for aid in account_ids]
        for fut in futures:
            fut.result()

    for aid in account_ids:
        if aid not in results_dict or results_dict[aid].get("reason") == "loading...":
            update_slot(aid, {"name": aid, "connected": False, "reason": "Timed out", "email": None})

    if json_mode:
        out = []
        for aid in account_ids:
            r = results_dict.get(aid, {"name": aid, "connected": False, "reason": "Timed out"})
            item = {
                "account": r["name"],
                "is_current": r.get("is_current", False),
                "connected": r.get("connected", False)
            }
            if r.get("connected"):
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
                    h_frac = h.get("fraction")
                    h_time, _ = format_time_left(h.get("reset_time"), h.get("desc"), h_frac)
                    raw_h_time = re.sub(r"\033\[[0-9;]*m", "", h_time).strip()
                item["gemini_5h"] = {
                    "remaining_fraction": h.get("fraction"),
                    "remaining_percentage": None if h.get("disabled") else (int(round(h["fraction"] * 100)) if h.get("fraction") is not None else None),
                    "reset_time": h.get("reset_time"),
                    "time_left": raw_h_time,
                    "disabled": h.get("disabled", False)
                }
            else:
                item["email"] = r.get("email")
                item["reason"] = r.get("reason", "Not connected")
            out.append(item)
        print(json.dumps(out, indent=2))
    elif not is_tty:
        print(b(f"╭─{dash_acc}─┬─{dash_data}─┬─{dash_data}─╮"))
        print(b("│ ") + c(f"{acc_hdr:<{W_ACC}}", "bold") + b(" │ ") +
              c(f"{gw_hdr:<{W_DATA}}", "bold") + b(" │ ") +
              c(f"{g5_hdr:<{W_DATA}}", "bold") + b(" │"))
        print(b(f"├─{dash_acc}─┼─{dash_data}─┼─{dash_data}─┤"))
        for i, aid in enumerate(account_ids):
            if show_email and i > 0:
                print(b(f"├─{dash_acc}─┼─{dash_data}─┼─{dash_data}─┤"))
            r = results_dict.get(aid, {"name": aid, "connected": False, "reason": "Error"})
            print(format_row(r))
            if show_email:
                print(format_email_row(r.get("email")))
        print(b(f"╰─{dash_acc}─┴─{dash_data}─┴─{dash_data}─╯"))
    PYEOF
  '';
in {
  home.packages =
    [
      antigravityCli
      agyn
      agy-usage
    ]
    ++ agyWrappers;

  # Declarative Antigravity settings and completed onboarding state
  home.file.".gemini/antigravity-cli/settings.json" = {
    text = builtins.toJSON antigravitySettings;
    force = true;
  };

  home.file.".gemini/antigravity-cli/cache/onboarding.json" = {
    text = builtins.toJSON {
      consumerOnboardingComplete = true;
      enterpriseOnboardingComplete = false;
      onboardingComplete = true;
    };
    force = true;
  };

  home.file.".gemini/antigravity-cli/jetski_state.pbtxt" = {
    text = ''
      post_onboarding:  {
        completed_steps:  POST_ONBOARDING_STEP_TYPE_MANAGER_WELCOME
        completed_steps:  POST_ONBOARDING_STEP_TYPE_USAGE_MODE
        completed_steps:  POST_ONBOARDING_STEP_TYPE_AGENT_CONFIGURATION
        completed_steps:  POST_ONBOARDING_STEP_TYPE_ADD_WORKSPACE
      }
      installation_uuid:  "231838c3-0c7e-4b19-97d6-51b12fdc0f84"
      migrations:  {
        key:  3
        value:  MIGRATION_STATUS_COMPLETED
      }
      migrations:  {
        key:  4
        value:  MIGRATION_STATUS_COMPLETED
      }
      migrations:  {
        key:  5
        value:  MIGRATION_STATUS_COMPLETED
      }
    '';
    force = true;
  };

  home.file.".gemini/settings.json" = {
    text = builtins.toJSON {
      security.auth.selectedType = "oauth-personal";
      general = {
        vimMode = true;
        preferredEditor = "neovim";
      };
      telemetry = {
        enabled = false;
      };
    };
    force = true;
  };

  home.file.".gemini/config/mcp_config.json" = {
    text = builtins.toJSON mcpConfig;
    force = true;
  };

  home.file.".gemini/antigravity-cli/bin/agy-usage" = {
    source = "${agy-usage}/bin/agy-usage";
    force = true;
  };
}
