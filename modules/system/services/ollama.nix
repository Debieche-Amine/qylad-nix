{
  config,
  lib,
  pkgs,
  ...
}: {
  # services.open-webui.enable = true;

  services.ollama = {
    enable = true;
    port = 11434;

    # openFirewall = true;

    # host = "0.0.0.0";

    package = pkgs.unstable.ollama-vulkan;

    loadModels = [
      # "llama3.1:8b"
      # "llama3.2:3b"
    ];
  };
}
