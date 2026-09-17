{pkgs, ...}: {
  home.packages = [
    pkgs.gnome-text-editor
  ];

  dconf.settings = {
    "org/gnome/TextEditor" = {
      show-line-numbers = true;
      highlight-current-line = true;
      highlight-matching-brackets = true;
      tab-width = 4;
      indent-style = "space";
      auto-indent = true;
      wrap-text = true;
      restore-session = false;
      show-map = false;
      show-right-margin = false;
    };
  };
}
