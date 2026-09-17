{pkgs, ...}: {
  systemd.services.good-morning-chatgpt = {
    description = "Good morning chatgpt";
    serviceConfig = {
      Type = "oneshot";
      User = "qylad";
      # ExecStart = "${pkgs.unstable.pi-coding-agent}/bin/pi --model gpt-5.4-mini:off --provider openai-codex -p hello";
      ExecStart = "/etc/profiles/per-user/qylad/bin/codex3 exec --skip-git-repo-check -m gpt-5.4-mini -c model_reasoning_effort=\"none\" hello";
    };
  };

  systemd.timers.good-morning-chatgpt = {
    description = "Trigger Good Morning every X minuts";
    wantedBy = ["timers.target"];

    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "45m";
      Unit = "good-morning-chatgpt.service";
    };
  };
}
