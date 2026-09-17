{pkgs, ...}: {
  environment.sessionVariables = {
    TERM = "xterm-256color";
  };

  environment.systemPackages = with pkgs; [
    libnotify
  ];
}
