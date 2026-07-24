{ config, pkgs, lib, ... }:

let
  bibataHyprcursor = pkgs.runCommand "bibata-modern-classic-hyprcursor"
    {
      inherit (pkgs.bibata-cursors) version;
      nativeBuildInputs = [ pkgs.hyprcursor pkgs.xcur2png ];
    }
    ''
      work=$(mktemp -d)
      hyprcursor-util -x ${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Classic -o "$work"
      extracted="$work/extracted_Bibata-Modern-Classic"
      sed -i 's/name = Extracted Theme/name = Bibata-Modern-Classic/' "$extracted/manifest.hl"
      outdir=$(mktemp -d)
      hyprcursor-util -c "$extracted" -o "$outdir"
      mkdir -p $out/share/icons
      mv "$outdir/theme_Bibata-Modern-Classic" "$out/share/icons/Bibata-Modern-Classic"
      rm -rf "$work" "$outdir"
    '';
in {
  home.packages = with pkgs; [
    qt6Packages.qtwayland
    libsForQt5.qtwayland
    qt6Packages.qtstyleplugin-kvantum
    libsForQt5.qtstyleplugin-kvantum
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    pkgs.kdePackages.breeze-icons

    bibataHyprcursor
    hyprcursor
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GTK_CSD = "0";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    GTK_USE_PORTAL = "1";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Bibata-Modern-Classic";
    HYPRCURSOR_SIZE = "24";
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    qt5ctSettings = {
      Appearance = {
        style = "kvantum";
        icon_theme = "breeze-dark";
        #color_scheme_path = "${config.home.homeDirectory}/.config/qt5ct/style-colors.conf";
      };
      Fonts = {
        fixed = "\"Monospace,10,-1,5,50,0,0,0,0,0\"";
        general = "\"Sans Serif,10,-1,5,50,0,0,0,0,0\"";
      };
    };
    qt6ctSettings = config.qt.qt5ctSettings;
    #style.name = "kvantum"; <-- this forces the style, better to do it through qtct
    kvantum = {
      enable = true;
      settings = {
        General = {
          theme = "catppuccin-macchiato-blue";
        };
      };
      themes = [
        (pkgs.catppuccin-kvantum.override { variant = "macchiato"; accent = "blue"; })
      ];
    };
  };

  systemd.user.sessionVariables = config.home.sessionVariables;

  # Subpixel antialiasing breaks Hypr-DarkWindow chromakey (colored fringe pixels).
  fonts.fontconfig = {
    enable = true;
    subpixelRendering = "none";
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "breeze-dark";
      package = pkgs.kdePackages.breeze-icons;
    };
    colorScheme = "dark";
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
    theme.name = "catppuccin-mocha-blue-standard";
    theme.package = pkgs.catppuccin-gtk;
    #for some reason .theme only sets gtk2-3 by default
    gtk4.theme = config.gtk.theme;
    #this is needed because .gtkrc-2.0 breaks somehow
    gtk2.force = true;
  };

  #home.file.".gtkrc-2.0".force = lib.mkForce true;

  xdg.configFile."kdeglobals".text = ''
    [KDE]
    SingleClick=false
    [Icons]
    Theme=breeze-dark
  '';


  xdg.configFile."rofi/spotlight.rasi".text = ''
    * {
        bg: #1e1e2e;
        bg-alt: #313244;
        fg: #cdd6f4;
        fg-alt: #a6adc8;
        border: #94e2d5;

        background-color: transparent;
        text-color: @fg;
        margin: 0;
        padding: 0;
        spacing: 0;
    }

    window {
        width: 600px;
        background-color: @bg;
        border: 2px;
        border-color: @border;
        border-radius: 12px;
        padding: 20px;
        location: center;
        anchor: center;
    }

    mainbox {
        children: [ inputbar, listview ];
    }

    inputbar {
        background-color: @bg-alt;
        border-radius: 8px;
        padding: 12px;
        children: [ prompt, entry ];
    }

    prompt {
        text-color: @fg-alt;
        padding: 0 10px 0 0;
    }

    entry {
        placeholder: "Search...";
        placeholder-color: @fg-alt;
    }

    listview {
        lines: 8;
        padding: 10px 0 0 0;
        scrollbar: false;
    }

    element {
        padding: 10px;
        border-radius: 8px;
    }

    element selected {
        background-color: @bg-alt;
        text-color: @border;
    }

    element-text {
        vertical-align: 0.5;
    }
  '';

  xdg.configFile."avizo/config.ini".text = ''
    [default]
    background = rgba(30, 30, 46, 0.95)
    border-color = rgba(148, 226, 213, 0.9)
    bar-fg-color = rgba(148, 226, 213, 0.95)
    bar-bg-color = rgba(49, 50, 68, 0.9)
    border-radius = 12
    border-width = 2
    padding = 20
    y-offset = 0.12
    x-offset = 0.5
    time = 1.5
    fade-in = 0.15
    fade-out = 0.3
  '';

}
