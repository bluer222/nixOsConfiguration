{ config, pkgs, lib, ... }:

let
  catppuccinKde = pkgs.catppuccin-kde;
  catppuccinGtk = pkgs.catppuccin-gtk;

  colorSchemeName = "CatppuccinMochaBlue";
  colorSchemeHomePath = "${config.xdg.dataHome}/color-schemes/${colorSchemeName}.colors";
  gtkThemeName = "catppuccin-mocha-blue-standard";
  iconThemeName = "breeze-dark";

  themeEnv = [
    "QT_QPA_PLATFORM=wayland"
    "QT_QPA_PLATFORMTHEME=kde"
    "COLOR_SCHEME=${colorSchemeName}"
    "KDEHOME=${config.home.homeDirectory}/.config"
    "KDE_SESSION_VERSION=6"
    "XDG_MENU_PREFIX=plasma-"
    "GTK_CSD=0"
  ];

  kdeglobalsText = ''
    [Icons]
    Theme=${iconThemeName}

    [General]
    widgetStyle=Breeze
    ColorScheme=${colorSchemeName}
    AccentColor=140,170,238

    [KDE]
    widgetStyle=Breeze
    colorScheme=${colorSchemeName}
    LookAndFeelPackage=Catppuccin-Mocha-Blue

    [UiSettings]
    ColorScheme=${colorSchemeName}
  '';

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
    platformTheme.name = "kde";
  };

  home.packages = with pkgs; [
    hyprland-qt-support
    catppuccinKde
    catppuccinGtk
    kdePackages.qtwayland
    kdePackages.plasma-integration
    kdePackages.breeze
    kdePackages.breeze-icons
    libsForQt5.qtwayland
    bibata-cursors
    bibataHyprcursor
    hyprcursor
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "kde";
    COLOR_SCHEME = colorSchemeName;
    KDEHOME = "${config.home.homeDirectory}/.config";
    KDE_SESSION_VERSION = "6";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_MENU_PREFIX = "plasma-";
    GDK_BACKEND = "wayland,x11";
    GTK_CSD = "0";
    BROWSER = "brave";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    GTK_USE_PORTAL = "1";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Bibata-Modern-Classic";
    HYPRCURSOR_SIZE = "24";
  };

  systemd.user.services.hyprpolkitagent.serviceConfig.Environment = themeEnv;

  xdg.configFile."hypr/scripts/apply-desktop-theme.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      if [ -x ${pkgs.dconf}/bin/dconf ] && [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" || true
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'${gtkThemeName}'" || true
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/icon-theme "'${iconThemeName}'" || true
      fi
    '';
  };

  home.activation.desktopThemePrefs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${config.home.homeDirectory}/.config/hypr/scripts/apply-desktop-theme.sh || true
  '';

  home.activation.importUserEnvironment = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Ensure systemd --user imports the environment so GUI services and autostarted
    # apps see `QT_QPA_PLATFORMTHEME` and related variables.
    $DRY_RUN_CMD systemctl --user import-environment || true
  '';

  xdg.dataFile."color-schemes/${colorSchemeName}.colors".source =
    "${catppuccinKde}/share/color-schemes/${colorSchemeName}.colors";

  xdg.configFile."environment.d/11-hyprland-theme.conf".text =
    lib.concatStringsSep "\n" themeEnv;

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

  xdg.configFile."hypr/application-style.conf".text = ''
    roundness = 0
    border_width = 2
    reduce_motion = false
  '';

  xdg.configFile."kdeglobals".text = kdeglobalsText;

  xdg.configFile."kdedefaults/kdeglobals".text = kdeglobalsText;

  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=1
    gtk-theme-name=${gtkThemeName}
    gtk-icon-theme-name=${iconThemeName}
    gtk-cursor-theme-name=Bibata-Modern-Classic
    gtk-cursor-theme-size=24
    gtk-decoration-layout=
  '';

  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=1
    gtk-theme-name=${gtkThemeName}
    gtk-icon-theme-name=${iconThemeName}
    gtk-decoration-layout=
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
