{ config, pkgs, ... }:

{
  qt = {
    enable = true;
    style = {
      name = "kvantum";
      package = pkgs.catppuccin-kvantum;
    };
    platformTheme.name = "qtct";
  };

  home.packages = with pkgs; [
    catppuccin-kvantum
    libsForQt5.qt5ct
    kdePackages.qt6ct
    kdePackages.qtwayland
    hyprland-qt-support
  ];

  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-frappe-blue
  '';

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    style=kvantum
    icon_theme=breeze-dark
    standard_dialogs=default
    palette=${pkgs.kdePackages.qt6ct}/share/qt6ct/colors/darker.conf
  '';

  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    style=kvantum
    icon_theme=breeze-dark
    standard_dialogs=default
    palette=${pkgs.libsForQt5.qt5ct}/share/qt5ct/colors/darker.conf
  '';

  xdg.configFile."kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark
    AccentColor=94,226,213

    [Icons]
    Theme=breeze-dark

    [KDE]
    widgetStyle=Kvantum
    colorScheme=BreezeDark

    [UiSettings]
    ColorScheme=qt6ct
  '';

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Mocha-Standard-Teal-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "teal" ];
        size = "standard";
        tweaks = [ "rimless" "black" ];
        variant = "mocha";
      };
    };
    iconTheme = {
      name = "breeze-dark";
      package = pkgs.kdePackages.breeze-icons;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.theme = config.gtk.theme;
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Catppuccin-Mocha-Standard-Teal-Dark";
    icon-theme = "breeze-dark";
  };

  xdg.configFile."rofi/spotlight.rasi".text = ''
    * {
        bg: #1e1e2ee6;
        bg-alt: #313244e6;
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
}
