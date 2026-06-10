{ config, pkgs, ... }:

{
  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
    style = {
      name = "kvantum";
      package = pkgs.catppuccin-kvantum;
    };
  };

  home.packages = with pkgs; [
    hyprland-qt-support
    catppuccin-kvantum
    kdePackages.qtwayland
    kdePackages.qt6ct
    kdePackages.breeze-icons
  ];

  xdg.configFile."hypr/application-style.conf".text = ''
    roundness = 0
    border_width = 2
    reduce_motion = false
  '';

  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-frappe-blue
  '';

  # Kvantum only reads themes from ~/.config/Kvantum/<name>/ — symlink from nix store.
  xdg.configFile."Kvantum/catppuccin-frappe-blue".source =
    "${pkgs.catppuccin-kvantum}/share/Kvantum/catppuccin-frappe-blue";

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    style=kvantum
    icon_theme=breeze-dark
    standard_dialogs=default
    palette=${pkgs.kdePackages.qt6ct}/share/qt6ct/colors/darker.conf
  '';

  xdg.configFile."kdeglobals".text = ''
    [Icons]
    Theme=breeze-dark

    [KDE]
    widgetStyle=Kvantum
    colorScheme=BreezeDark

    [General]
    ColorScheme=BreezeDark
    AccentColor=94,226,213
  '';

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
