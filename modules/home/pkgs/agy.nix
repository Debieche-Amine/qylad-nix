{
  config,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  antigravityCli = pkgs.unstable.antigravity-cli;

  # Declarative Antigravity settings & preferences
  antigravitySettings = {
    artifactReviewPolicy = "agent-decides";
    editorMode = "vim";
    vimInsertFirst = true;
    model = "Gemini 3.8 Flash (High)";
    showFeedbackSurvey = false;
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

  # agy-switch: Switch the active account in ~/.gemini/antigravity-cli
  agy-switch = pkgs.writeShellScriptBin "agy-switch" ''
    set -euo pipefail

    ACCOUNTS_DIR="$HOME/.gemini/accounts"
    CLI_DIR="$HOME/.gemini/antigravity-cli"
    ACTIVE_TOKEN="$CLI_DIR/antigravity-oauth-token"
    CURRENT_FILE="$ACCOUNTS_DIR/.current"

    mkdir -p "$ACCOUNTS_DIR" "$CLI_DIR"

    sync_current() {
      if [ -f "$CURRENT_FILE" ] && [ -f "$ACTIVE_TOKEN" ]; then
        local cur_id
        cur_id=$(cat "$CURRENT_FILE" | tr -d '[:space:]')
        if [ -n "$cur_id" ] && [ -d "$ACCOUNTS_DIR/$cur_id" ]; then
          cp -f "$ACTIVE_TOKEN" "$ACCOUNTS_DIR/$cur_id/antigravity-oauth-token"
          if [ -f "$CLI_DIR/.cached_email" ]; then
            cp -f "$CLI_DIR/.cached_email" "$ACCOUNTS_DIR/$cur_id/email"
          fi
        fi
      fi
    }

    list_accounts() {
      sync_current
      local cur_id=""
      [ -f "$CURRENT_FILE" ] && cur_id=$(cat "$CURRENT_FILE" | tr -d '[:space:]')

      echo -e "\033[1mAntigravity Accounts\033[0m (~/.gemini/accounts):"
      echo "──────────────────────────────────────────────"
      local found=0
      for dir in $(find "$ACCOUNTS_DIR" -mindepth 1 -maxdepth 1 -type d | sort -V); do
        local id
        id=$(basename "$dir")
        local email="(no email)"
        [ -f "$dir/email" ] && email=$(cat "$dir/email" | tr -d '[:space:]')

        if [ "$id" = "$cur_id" ]; then
          printf "  \033[1;32m* [%-3s]\033[0m %-30s \033[1;32m(active)\033[0m\n" "$id" "$email"
        else
          printf "    [%-3s] %-30s\n" "$id" "$email"
        fi
        found=1
      done

      if [ $found -eq 0 ]; then
        echo "  No accounts found."
      fi
      echo "──────────────────────────────────────────────"
      echo "Usage: agy-switch <id>        Switch active account"
      echo "       agy-switch add <id>     Add a new account slot"
      echo "       agy-switch save <id>    Save current login to slot <id>"
      echo "       agy-switch current      Show current active account"
    }

    switch_account() {
      local target_id="$1"
      local target_dir="$ACCOUNTS_DIR/$target_id"

      if [ ! -d "$target_dir" ] || [ ! -f "$target_dir/antigravity-oauth-token" ]; then
        echo -e "\033[1;31mError:\033[0m Account '$target_id' not found in $ACCOUNTS_DIR" >&2
        echo "Run 'agy-switch' to list available accounts." >&2
        exit 1
      fi

      sync_current

      cp -f "$target_dir/antigravity-oauth-token" "$ACTIVE_TOKEN"
      chmod 600 "$ACTIVE_TOKEN"

      local target_email="(no email)"
      if [ -f "$target_dir/email" ]; then
        cp -f "$target_dir/email" "$CLI_DIR/.cached_email"
        target_email=$(cat "$target_dir/email" | tr -d '[:space:]')
      fi

      echo "$target_id" > "$CURRENT_FILE"
      echo -e "\033[1;32m✔ Switched to account [$target_id]:\033[0m $target_email"
    }

    save_account() {
      local target_id="$1"
      local target_dir="$ACCOUNTS_DIR/$target_id"
      mkdir -p "$target_dir"

      if [ ! -f "$ACTIVE_TOKEN" ]; then
        echo -e "\033[1;31mError:\033[0m No active token found in $ACTIVE_TOKEN" >&2
        exit 1
      fi

      cp -f "$ACTIVE_TOKEN" "$target_dir/antigravity-oauth-token"
      chmod 600 "$target_dir/antigravity-oauth-token"

      local email=""
      if [ $# -ge 2 ]; then
        email="$2"
      elif [ -f "$CLI_DIR/.cached_email" ]; then
        email=$(cat "$CLI_DIR/.cached_email" | tr -d '[:space:]')
      fi

      if [ -n "$email" ]; then
        echo "$email" > "$target_dir/email"
      fi

      echo "$target_id" > "$CURRENT_FILE"
      echo -e "\033[1;32m✔ Saved current login as account [$target_id]:\033[0m $email"
    }

    add_account() {
      local new_id="$1"
      local target_dir="$ACCOUNTS_DIR/$new_id"

      if [ -d "$target_dir" ] && [ -f "$target_dir/antigravity-oauth-token" ]; then
        echo -e "\033[1;33mWarning:\033[0m Account '$new_id' already exists. Use 'agy-switch $new_id' to switch to it, or 'agy-switch save $new_id' to overwrite." >&2
        exit 1
      fi

      sync_current
      rm -f "$ACTIVE_TOKEN" "$CLI_DIR/.cached_email"
      echo "$new_id" > "$CURRENT_FILE"

      echo -e "\033[1;36mAccount slot [$new_id] prepared.\033[0m"
      echo "Now run 'agy' to sign in with your Google account."
      echo "Once logged in, run: agy-switch save $new_id"
    }

    case "''${1:-}" in
      "")
        list_accounts
        ;;
      "list"|"-l"|"--list")
        list_accounts
        ;;
      "current"|"whoami"|"status")
        sync_current
        cur_id=""
        [ -f "$CURRENT_FILE" ] && cur_id=$(cat "$CURRENT_FILE" | tr -d '[:space:]')
        email=""
        [ -f "$CLI_DIR/.cached_email" ] && email=$(cat "$CLI_DIR/.cached_email" | tr -d '[:space:]')
        echo "Active account: [$cur_id] $email"
        ;;
      "save")
        if [ $# -lt 2 ]; then
          echo "Usage: agy-switch save <id> [email]" >&2
          exit 1
        fi
        save_account "$2" "''${3:-}"
        ;;
      "add"|"new"|"login")
        if [ $# -lt 2 ]; then
          echo "Usage: agy-switch add <id>" >&2
          exit 1
        fi
        add_account "$2"
        ;;
      *)
        switch_account "$1"
        ;;
    esac
  '';

  # agyn: Runner for executing commands using a specific account with declarative settings
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
    ACCOUNT_DIR="$REAL_HOME/.gemini/accounts/$ACCOUNT_ID"
    TOKEN_FILE="$ACCOUNT_DIR/antigravity-oauth-token"

    if [ ! -f "$TOKEN_FILE" ]; then
      echo -e "\033[1;31mError:\033[0m Account '$ACCOUNT_ID' not found in ~/.gemini/accounts" >&2
      exit 1
    fi

    PROFILE_HOME="$ACCOUNT_DIR/profile"
    PROFILE_CLI="$PROFILE_HOME/.gemini/antigravity-cli"
    mkdir -p "$PROFILE_CLI/cache" "$PROFILE_HOME/.gemini"

    # Symlink declarative home-manager settings so all accounts share the exact same config
    ln -sf "$REAL_HOME/.gemini/antigravity-cli/settings.json" "$PROFILE_CLI/settings.json"
    ln -sf "$REAL_HOME/.gemini/antigravity-cli/cache/onboarding.json" "$PROFILE_CLI/cache/onboarding.json"
    ln -sf "$REAL_HOME/.gemini/antigravity-cli/jetski_state.pbtxt" "$PROFILE_CLI/jetski_state.pbtxt"
    ln -sf "$REAL_HOME/.gemini/settings.json" "$PROFILE_HOME/.gemini/settings.json"

    # Ensure account token and email are synced
    if [ ! -f "$PROFILE_CLI/antigravity-oauth-token" ] || [ "$TOKEN_FILE" -nt "$PROFILE_CLI/antigravity-oauth-token" ]; then
      cp -f "$TOKEN_FILE" "$PROFILE_CLI/antigravity-oauth-token"
    fi

    if [ -f "$ACCOUNT_DIR/email" ]; then
      cp -f "$ACCOUNT_DIR/email" "$PROFILE_CLI/.cached_email"
    fi

    cleanup() {
      if [ -f "$PROFILE_CLI/antigravity-oauth-token" ]; then
        cp -f "$PROFILE_CLI/antigravity-oauth-token" "$TOKEN_FILE"
      fi
    }
    trap cleanup EXIT INT TERM

    export HOME="$PROFILE_HOME"
    export XDG_CONFIG_HOME="$PROFILE_HOME/.config"
    export XDG_DATA_HOME="$PROFILE_HOME/.local/share"
    export XDG_CACHE_HOME="/tmp/agy-cache-$ACCOUNT_ID"
    export GOPATH="$REAL_HOME/go"
    export CARGO_HOME="$REAL_HOME/.cargo"
    export RUSTUP_HOME="$REAL_HOME/.rustup"

    exec ${antigravityCli}/bin/agy "$@"
  '';

  # Backward compatibility wrappers: agy2, agy3, ..., agy10
  mkAgyWrapper = id:
    pkgs.writeShellScriptBin "agy${toString id}" ''
      exec ${agyn}/bin/agyn ${toString id} "$@"
    '';
  agyWrappers = map mkAgyWrapper [2 3 4 5 6 7 8 9 10];

  # agy-usage: Parallel account usage checker querying ~/.gemini/accounts
  agy-usage = pkgs.writeShellScriptBin "agy-usage" ''
    exec ${pkgs.python3}/bin/python3 - "$@" << 'PYEOF'
    import os
    import sys
    import json
    import re
    import tempfile
    import subprocess
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

    accounts_dir = os.path.expanduser("~/.gemini/accounts")
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
    account_ids.sort(key=lambda x: int(x) if x.isdigit() else x)

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

    def check_account(acc_id):
        acc_path = os.path.join(accounts_dir, acc_id)
        tok_file = os.path.join(acc_path, "antigravity-oauth-token")
        email_file = os.path.join(acc_path, "email")
        if not os.path.exists(tok_file):
            return {"name": f"acc-{acc_id}", "connected": False, "reason": "No token", "email": None}

        email = None
        if os.path.exists(email_file):
            try:
                with open(email_file) as f:
                    email = f.read().strip()
            except Exception:
                pass

        with tempfile.TemporaryDirectory(prefix=f"agy-usage-{acc_id}-") as tmpdir:
            tmp_cli = os.path.join(tmpdir, ".gemini", "antigravity-cli")
            os.makedirs(tmp_cli, exist_ok=True)
            os.symlink(tok_file, os.path.join(tmp_cli, "antigravity-oauth-token"))
            env = dict(os.environ, HOME=tmpdir)
            try:
                res = subprocess.run(
                    ["${antigravityCli}/bin/agy", "-p", "/usage", "--output-format", "json"],
                    stdin=subprocess.DEVNULL,
                    capture_output=True, text=True, timeout=25, env=env
                )
                if "Authentication required" in res.stdout or "Authentication required" in res.stderr:
                    return {"name": acc_id, "connected": False, "reason": "Auth expired", "email": email}
                if res.returncode != 0:
                    return {"name": acc_id, "connected": False, "reason": "Not connected", "email": email}

                data = json.loads(res.stdout)
                if data.get("status") != "SUCCESS":
                    return {"name": acc_id, "connected": False, "reason": "Not connected", "email": email}

                groups = data.get("command", {}).get("data", {}).get("groups", [])
                gemini = next((g for g in groups if g.get("name") == "Gemini Models"), None)
                if not gemini:
                    return {"name": acc_id, "connected": False, "reason": "No Gemini data", "email": email}

                buckets = gemini.get("buckets", [])
                w_b = next((b for b in buckets if b.get("id") == "gemini-weekly" or b.get("window") == "weekly"), {})
                h_b = next((b for b in buckets if b.get("id") == "gemini-5h" or b.get("window") == "5h"), {})

                return {
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
            except Exception:
                return {"name": acc_id, "connected": False, "reason": "Timeout/Error", "email": email}

    with ThreadPoolExecutor(max_workers=8) as ex:
        results = list(ex.map(check_account, account_ids))

    if json_mode:
        out = []
        for r in results:
            item = {
                "account": r["name"],
                "is_current": r.get("is_current", False),
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
                item["email"] = r.get("email")
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
        is_cur = r.get("is_current", False)
        display_name = f"*{name}" if is_cur else name
        name_fmt = c(f"{display_name:<{W_ACC}}", "bright_cyan" if r["connected"] else "dim")

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
  home.packages =
    [
      antigravityCli
      agy-switch
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
    };
    force = true;
  };
}
