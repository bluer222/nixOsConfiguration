{ config, pkgs, ... }:

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
  qt = {
    enable = true;
    platformTheme = {
      name = "qt6ct";
      package = pkgs.kdePackages.qt6ct;
    };
    # style.package must NOT be catppuccin-kvantum — that package is themes only.
    # HM installs libsForQt5.qtstyleplugin-kvantum + qt6Packages.qtstyleplugin-kvantum.
    style.name = "kvantum";
  };

  home.packages = with pkgs; [
    hyprland-qt-support
    catppuccin-kvantum
    kdePackages.qtwayland
    kdePackages.qt6ct
    kdePackages.breeze
    kdePackages.breeze-icons
    bibata-cursors
    bibataHyprcursor
    hyprcursor
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_STYLE_OVERRIDE = "kvantum";
    COLOR_SCHEME = "BreezeDark";
    KDEHOME = "${config.home.homeDirectory}/.config";
    KDE_SESSION_VERSION = "6";
    XDG_CURRENT_DESKTOP = "Hyprland:KDE";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_MENU_PREFIX = "plasma-";
    GDK_BACKEND = "wayland,x11";
    BROWSER = "brave";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    GTK_USE_PORTAL = "1";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Bibata-Modern-Classic";
    HYPRCURSOR_SIZE = "24";
  };

  # Subpixel antialiasing breaks Hypr-DarkWindow chromakey (colored fringe pixels).
  xdg.configFile."fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <match target="font">
        <edit name="rgba" mode="assign"><const>none</const></edit>
        <edit name="lcdfilter" mode="assign"><const>lcdnone</const></edit>
      </match>
    </fontconfig>
  '';

  xdg.dataFile."color-schemes/BreezeDark.colors".source =
    "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";

  xdg.configFile."hypr/application-style.conf".text = ''
    roundness = 0
    border_width = 2
    reduce_motion = false
  '';

  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-frappe-blue
  '';

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
    widgetStyle=kvantum
    colorScheme=BreezeDark

    [General]
    ColorScheme=BreezeDark
    AccentColor=94,226,213
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
}
