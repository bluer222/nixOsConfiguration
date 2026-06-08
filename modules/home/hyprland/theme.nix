{ config, pkgs, ... }:

{
  # -----------------------------------------------------
  # Qt Theming (Catppuccin via Kvantum)
  # -----------------------------------------------------
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  home.packages = with pkgs; [
    catppuccin-kvantum
    libsForQt5.qt5ct
    kdePackages.qt6ct
  ];

  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-mocha-teal
  '';

  # -----------------------------------------------------
  # GTK Theming (Fallback if needed)
  # -----------------------------------------------------
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
  };

  # -----------------------------------------------------
  # Rofi Config (Spotlight style)
  # -----------------------------------------------------
  xdg.configFile."rofi/spotlight.rasi".text = ''
    * {
        bg: #1e1e2ee6; /* Mocha Base with transparency */
        bg-alt: #313244e6; /* Surface0 */
        fg: #cdd6f4; /* Text */
        fg-alt: #a6adc8; /* Subtext0 */
        border: #94e2d5; /* Teal active border */

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
