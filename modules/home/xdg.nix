{pkgs, ...}: {
  home.packages = [
    pkgs.zathura
    pkgs.imv
    pkgs.mpv
    # pkgs.vivaldi
    pkgs.file-roller
    pkgs.gnome-disk-utility
    pkgs.gnome-text-editor
    # pkgs.thunar
  ];

  xdg.configFile."xfce4/helpers.rc".text = ''
    TerminalEmulator=kitty
  '';

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Web
      "text/html" = ["zen-beta.desktop"];
      "application/xhtml+xml" = ["zen-beta.desktop"];
      "x-scheme-handler/http" = ["zen-beta.desktop"];
      "x-scheme-handler/https" = ["zen-beta.desktop"];
      "x-scheme-handler/about" = ["zen-beta.desktop"];
      "x-scheme-handler/unknown" = ["zen-beta.desktop"];

      # PDF & PostScript
      "application/pdf" = ["org.pwmt.zathura.desktop"];
      "application/postscript" = ["org.pwmt.zathura.desktop"];
      "application/epub+zip" = ["org.pwmt.zathura.desktop"];

      # Images
      "image/jpeg" = ["swayimg.desktop"];
      "image/png" = ["swayimg.desktop"];
      "image/gif" = ["swayimg.desktop"];
      "image/webp" = ["swayimg.desktop"];
      "image/bmp" = ["swayimg.desktop"];
      "image/tiff" = ["swayimg.desktop"];
      "image/svg+xml" = ["swayimg.desktop"];
      "image/x-portable-pixmap" = ["swayimg.desktop"];
      "image/x-portable-graymap" = ["swayimg.desktop"];
      "image/x-portable-bitmap" = ["swayimg.desktop"];
      "image/x-xpixmap" = ["swayimg.desktop"];
      "image/x-xbitmap" = ["swayimg.desktop"];
      "image/avif" = ["swayimg.desktop"];
      "image/heif" = ["swayimg.desktop"];

      # Video
      "video/mp4" = ["mpv.desktop"];
      "video/x-matroska" = ["mpv.desktop"];
      "video/webm" = ["mpv.desktop"];
      "video/x-msvideo" = ["mpv.desktop"];
      "video/quicktime" = ["mpv.desktop"];
      "video/mpeg" = ["mpv.desktop"];
      "video/ogg" = ["mpv.desktop"];

      # Audio
      "audio/mpeg" = ["mpv.desktop"];
      "audio/flac" = ["mpv.desktop"];
      "audio/ogg" = ["mpv.desktop"];
      "audio/opus" = ["mpv.desktop"];
      "audio/wav" = ["mpv.desktop"];
      "audio/x-wav" = ["mpv.desktop"];
      "audio/x-m4a" = ["mpv.desktop"];
      "audio/aac" = ["mpv.desktop"];

      # Archives
      "application/zip" = ["org.gnome.FileRoller.desktop"];
      "application/x-tar" = ["org.gnome.FileRoller.desktop"];
      "application/x-7z-compressed" = ["org.gnome.FileRoller.desktop"];
      "application/x-rar" = ["org.gnome.FileRoller.desktop"];
      "application/gzip" = ["org.gnome.FileRoller.desktop"];
      "application/x-bzip2" = ["org.gnome.FileRoller.desktop"];
      "application/x-xz" = ["org.gnome.FileRoller.desktop"];

      # Disk Images & ISOs (Mount as virtual drive)
      "application/x-cd-image" = ["gnome-disk-image-mounter.desktop"];
      "application/x-iso9660-image" = ["gnome-disk-image-mounter.desktop"];
      "application/x-raw-disk-image" = ["gnome-disk-image-mounter.desktop"];

      # Text
      "text/plain" = ["org.gnome.TextEditor.desktop"];
      "text/markdown" = ["org.gnome.TextEditor.desktop"];
      "text/x-python" = ["org.gnome.TextEditor.desktop"];
      "application/x-shellscript" = ["org.gnome.TextEditor.desktop"];
      "text/x-shellscript" = ["org.gnome.TextEditor.desktop"];
      "application/json" = ["org.gnome.TextEditor.desktop"];
      "application/xml" = ["org.gnome.TextEditor.desktop"];
      "text/xml" = ["org.gnome.TextEditor.desktop"];
      "text/x-makefile" = ["org.gnome.TextEditor.desktop"];
      "text/x-dockerfile" = ["org.gnome.TextEditor.desktop"];
      "text/x-cmake" = ["org.gnome.TextEditor.desktop"];

      # Generic & Fallback types (empty or unknown extensionless files)
      "application/octet-stream" = ["org.gnome.TextEditor.desktop"];
      "application/x-zerosize" = ["org.gnome.TextEditor.desktop"];

      # Directories
      "inode/directory" = ["thunar.desktop"];
    };
  };

  xdg.desktopEntries.gnome-disk-image-mounter = {
    name = "Disk Image Mounter";
    exec = "${pkgs.gnome-disk-utility}/bin/gnome-disk-image-mounter --writable %U";
    icon = "drive-removable-media";
    mimeType = [
      "application/x-cd-image"
      "application/x-iso9660-image"
      "application/x-raw-disk-image"
    ];
    noDisplay = true;
  };
}
