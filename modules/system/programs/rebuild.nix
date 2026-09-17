{pkgs, ...}: let
  rebuild = pkgs.writeShellApplication {
    name = "rebuild";

    runtimeInputs = with pkgs; [
      git
      alejandra
      nixos-rebuild
      nh
      coreutils
    ];

    text = ''
      FLAKE_PATH="$HOME/nixos"
      FLAKE_TARGET="$(hostname)"
      TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"

      NO_SUB=false
      ACTION="switch"
      USE_NH=false
      COMMIT_MSG=""

      usage() {
              cat <<'EOF'
      Usage:
        rebuild [action] [options]

      Actions:
        switch, --switch       Run switch action (default)
        test, --test           Run test action
        build, --build         Run build action

      Options:
        -m, --message MSG      Custom commit message (default: "nixos: (YYYYMMDD-HHMMSS)")
        --nh                   Use 'nh' instead of standard 'nixos-rebuild'
        --no-sub               Disable binary cache substituters (--option substitute false)
        -h, --help             Show this help message
      EOF
      }

      while [[ $# -gt 0 ]]; do
              case "$1" in
              --no-sub)
                      NO_SUB=true
                      shift
                      ;;
              -m | --message | --commit-message)
                      if [[ $# -lt 2 || "$2" == --* ]]; then
                              echo "Error: -m/--message requires a message string." >&2
                              exit 2
                      fi
                      COMMIT_MSG="$2"
                      shift 2
                      ;;
              switch | --switch)
                      ACTION="switch"
                      shift
                      ;;
              test | --test)
                      ACTION="test"
                      shift
                      ;;
              build | --build)
                      ACTION="build"
                      shift
                      ;;
              --nh)
                      USE_NH=true
                      shift
                      ;;
              --nixos-rebuild | --no-nh)
                      USE_NH=false
                      shift
                      ;;
              -h | --help)
                      usage
                      exit 0
                      ;;
              *)
                      echo "Unknown parameter: $1" >&2
                      usage >&2
                      exit 2
                      ;;
              esac
      done

      cd "$FLAKE_PATH" || exit 1

      alejandra . || exit 1

      git add -A || exit 1
      git diff --staged || exit 1

      NH_EXTRA_ARGS=()
      NIXOS_EXTRA_ARGS=()
      if [[ "$NO_SUB" == true ]]; then
              NH_EXTRA_ARGS=(-- --option substitute false)
              NIXOS_EXTRA_ARGS=(--option substitute false)
      fi

      COMMIT_AFTER_BUILD=false
      if [[ "$ACTION" == "switch" || -n "$COMMIT_MSG" ]]; then
              COMMIT_AFTER_BUILD=true
      fi

      case "$ACTION" in
      switch)
              if [[ "$USE_NH" == true ]]; then
                      if ! command -v nh &>/dev/null; then
                              echo "Error: 'nh' is not installed." >&2
                              exit 1
                      fi
                      CMD=(nh os switch "$FLAKE_PATH" --hostname "$FLAKE_TARGET" "''${NH_EXTRA_ARGS[@]}")
              else
                      CMD=(sudo nixos-rebuild switch --flake "$FLAKE_PATH#$FLAKE_TARGET" "''${NIXOS_EXTRA_ARGS[@]}")
              fi
              ;;
      test)
              if [[ "$USE_NH" == true ]]; then
                      if ! command -v nh &>/dev/null; then
                              echo "Error: 'nh' is not installed." >&2
                              exit 1
                      fi
                      CMD=(nh os test "$FLAKE_PATH" --hostname "$FLAKE_TARGET" "''${NH_EXTRA_ARGS[@]}")
              else
                      CMD=(sudo nixos-rebuild test --flake "$FLAKE_PATH#$FLAKE_TARGET" "''${NIXOS_EXTRA_ARGS[@]}")
              fi
              ;;
      build)
              CMD=(nixos-rebuild build --flake "$FLAKE_PATH#$FLAKE_TARGET" "''${NIXOS_EXTRA_ARGS[@]}")
              ;;
      esac

      # Remove the empty final array element produced when no extra arguments exist.
      if [[ "''${CMD[-1]}" == "" ]]; then
              unset 'CMD[-1]'
      fi

      printf '\nRunning:'
      printf ' %q' "''${CMD[@]}"
      printf '\n\n'

      if ! "''${CMD[@]}"; then
              echo
              echo "Build or activation failed; no commit was created." >&2
              exit 1
      fi

      echo
      echo "Build succeeded."

      if [[ "$COMMIT_AFTER_BUILD" == true ]]; then
              if git diff --cached --quiet; then
                      echo "No staged changes to commit."
              else
                      MSG="''${COMMIT_MSG:-nixos: ($TIMESTAMP)}"
                      git commit -m "$MSG" || exit 1
                      echo "Git commit created: $MSG"
              fi
      else
              echo "Skipping commit for test/build action."
      fi
    '';
  };
in {
  environment.systemPackages = [rebuild];
}
