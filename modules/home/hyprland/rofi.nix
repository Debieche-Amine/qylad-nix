{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = [pkgs.rofi];

  programs.rofi = {
    enable = true;
    modes = ["combi" "drun" "window" "run" "ssh"];
    extraConfig = {
      show-icons = true;
      matching = "fuzzy";
      combi-modes = "drun,window,run,ssh";
      combi-display-format = "{text}";
      display-combi = "Omni";
    };

    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      window = {
        width = mkLiteral "620px";
        border = 1;
        border-radius = 18;
        border-color = mkLiteral "@lightbg";
        background-color = lib.mkForce (mkLiteral "rgba(30, 30, 46, 0.75)");
        location = mkLiteral "center";
        anchor = mkLiteral "center";
      };

      mainbox = {
        padding = mkLiteral "14px";
        spacing = 10;
      };

      inputbar = {
        padding = mkLiteral "11px 13px";
        spacing = 10;
        border = 0;
        border-radius = 12;
        background-color = mkLiteral "@lightbg";
        children = map mkLiteral ["prompt" "entry"];
      };

      prompt = {
        text-color = lib.mkForce (mkLiteral "@blue");
        background-color = mkLiteral "transparent";
      };

      entry = {
        placeholder = "input";
        placeholder-color = mkLiteral "@lightfg";
        background-color = mkLiteral "transparent";
      };

      listview = {
        lines = 7;
        columns = 1;
        fixed-height = false;
        scrollbar = false;
        spacing = 3;
      };

      element = {
        padding = mkLiteral "10px 12px";
        spacing = 12;
        border = 0;
        border-radius = 10;
        background-color = mkLiteral "transparent";
      };

      element-icon.size = mkLiteral "28px";

      "element normal.normal".background-color = lib.mkForce (mkLiteral "transparent");
      "element alternate.normal".background-color = lib.mkForce (mkLiteral "transparent");

      "element selected.normal" = {
        border = 1;
        border-color = mkLiteral "@blue";
        background-color = lib.mkForce (mkLiteral "@lightbg");
        text-color = lib.mkForce (mkLiteral "@foreground");
      };
    };
  };
}
