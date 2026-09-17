{
  config,
  pkgs,
  ...
}: {
  programs.alacritty = {
    enable = true;

    settings = {
      # 2. Window essentials
      window = {
        dimensions = {
          columns = 120;
          lines = 30;
        };
        padding = {
          x = 5;
          y = 5;
        };
        dynamic_padding = true; # adjust padding automatically for font size
      };

      # 4. Scrollback
      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      # 5. Keybindings (examples, commented out)
      # keyboard = {
      #   bindings = [
      #     { key = "C"; mods = "Control|Shift"; action = "Copy"; }
      #     { key = "V"; mods = "Control|Shift"; action = "Paste"; }
      #   ];
      # };

      # 7. Visual tweaks (commented)
      # background_opacity = 0.95;
      # hide_cursor_when_typing = false;
    };
  };
}
