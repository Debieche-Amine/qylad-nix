{...}: {
  home.shellAliases = {
    kssh = "kitten ssh";
  };

  programs.kitty = {
    enable = true;

    extraConfig = ''
      font_features MapleMono-Regular +ss01 +ss02 +ss04
      font_features MapleMono-Bold +ss01 +ss02 +ss04
      font_features MapleMono-Italic +ss01 +ss02 +ss04
      font_features MapleMono-Light +ss01 +ss02 +ss04

      # Maple Mono has no Arabic glyphs.  Use a deliberately Arabic-capable
      # fallback for every Arabic Unicode block while retaining Maple Mono for
      # source code and all other text.
      symbol_map U+0600-U+06FF,U+0750-U+077F,U+0870-U+089F,U+08A0-U+08FF,U+FB50-U+FDFF,U+FE70-U+FEFF Noto Sans Arabic
    '';

    settings = {
      confirm_os_window_close = 0;
      scrollback_lines = 10000;
      enable_audio_bell = false;
      mouse_hide_wait = 60;
      window_padding_width = 2;

      wheel_scroll_multiplier = 5.0;
      touch_scroll_multiplier = 3.0;

      ## Tabs
      tab_title_template = "{index}";
      active_tab_font_style = "normal";
      inactive_tab_font_style = "normal";
      tab_bar_style = "powerline";
      tab_powerline_style = "angled";
    };

    keybindings = {
      ## Tabs
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";

      ## Unbind
      "ctrl+shift+left" = "no_op";
      "ctrl+shift+right" = "no_op";
    };
  };
}
