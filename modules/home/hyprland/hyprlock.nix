{pkgs, ...}: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      background = {
        monitor = "";
        blur_passes = 3;
        blur_size = 8;
        noise = 0.012;
        contrast = 1.05;
        brightness = 0.72;
        vibrancy = 0.18;
        vibrancy_darkness = 0.2;
      };

      label = [
        {
          monitor = "";
          text = "$TIME";
          font_family = "Maple Mono NF";
          font_size = 82;
          position = "0, 170";
          halign = "center";
          valign = "center";
          shadow_passes = 2;
          shadow_size = 5;
        }
        {
          monitor = "";
          text = "cmd[update:60000] date +\"%A, %d %B\"";
          font_family = "Maple Mono NF";
          font_size = 18;
          position = "0, 90";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "󰀄  $USER";
          font_family = "Maple Mono NF";
          font_size = 17;
          position = "0, -42";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = {
        monitor = "";
        size = "320, 58";
        position = "0, -115";
        halign = "center";
        valign = "center";
        outline_thickness = 2;
        rounding = 18;
        dots_center = true;
        fade_on_empty = false;
        placeholder_text = "<span foreground=\"##a89984\">Password</span>";
        fail_text = "<span foreground=\"##fb4934\">$FAIL <b>($ATTEMPTS)</b></span>";
        font_family = "Maple Mono NF";
        shadow_passes = 2;
        shadow_size = 8;
        shadow_color = "rgba(0, 0, 0, 0.45)";
      };
    };
  };
}
