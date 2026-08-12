{ config, pkgs, lib, ... }:

{
  #notes:
  #must leave kdeglobals alone, generated nocalia css
  #noctalia gtk theming needs adw-gtk3 and @import url("noctalia.css"); in extracss
  # general qt setup(not for kde apps):
  # qt5ct and 6ct theme apps, rendering provided by darkly, color scheme provided by noctalia
  # kde apps instead pick up from generated kdeglobals
  # all qt apps follow the configures style in qtct however for the color scheme this differs:
  # keysmith seems to reads from kdeglobals solely 
  # konsole gwenview and dolphin have a color scheme selector hidden in their menus.
  # partitionmanager and some other kde apps and most non kde apps use the system theme correctly

  home.packages = with pkgs; [
    bibata-cursors
    pkgs.kdePackages.breeze-icons
    
    qt6Packages.qtwayland
    libsForQt5.qtwayland
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    pkgs.darkly
    pkgs.adw-gtk3
  ];
  
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    qt5ctSettings = {
      Appearance = {
        style = "Darkly";
        icon_theme = "breeze-dark";
        color_scheme_path = "${config.home.homeDirectory}/.config/qt5ct/colors/noctalia.conf";
        custom_palette = true;
      };
      Fonts = {
        fixed = "\"FiraCode Nerd Font Mono,10,-1,5,50,0,0,0,0,0\"";
        general = "\"FiraCode Nerd Font,10,-1,5,50,0,0,0,0,0\"";
      };
    };
    qt6ctSettings = lib.recursiveUpdate config.qt.qt5ctSettings {
      Appearance.color_scheme_path = "${config.home.homeDirectory}/.config/qt6ct/colors/noctalia.conf";
    };
  };

  fonts.fontconfig = {
    enable = true;
    subpixelRendering = "none";
  };

  gtk = {
    enable = true;

    colorScheme = "dark";

    iconTheme = {
      name = "breeze-dark";
      package = pkgs.kdePackages.breeze-icons;
    };

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
    #noctalia theming needs adw-gtk3
    theme.name = "adw-gtk3-dark";
    theme.package = pkgs.adw-gtk3;
    font = {
      name = "FiraCode Nerd Font";
      size = 10;
      package = pkgs.nerd-fonts.fira-code;
    };
    #for some reason gtk.theme. is only for 2 and 3 so i need this
    gtk4.theme = config.gtk.theme;
    # noctalia theming
    gtk4.extraCss = ''
      @import url("noctalia.css");
      * {
          border-radius: 0px !important;
      }
      headerbar {
          min-height: 0px !important;
          height: 0px !important;
          padding: 0px !important;
          margin: 0px !important;
          border: none !important;
          background: none !important;
          box-shadow: none !important;
      }

      /* Ensure the underlying container elements inside the header bar are hidden */
      headerbar windowhandle, 
      headerbar box {
          min-height: 0px !important;
          height: 0px !important;
          padding: 0px !important;
          margin: 0px !important;
          opacity: 0 !important;
      }
    '';
    gtk3.extraCss = config.gtk.gtk4.extraCss;
    gtk2.force = true;
  };


  xdg.configFile."darklyrc".text = ''
    [Common]
    CornerRadius=1
    FancyMargins=false
    FloatingTitlebar=false
    ShadowSize=ShadowNone
    ShadowStrength=51

    [Style]
    DisableDolphinUrlNavigatorBackground=false
    RoundedRubberBandFrame=false
    ScrollBarSubLineButtons=2
    TabDrawHighlight=true
    TabsHeight=-5
    UnifiedTabBarKonsole=true

    [Windeco]
    RoundedCorners=false
  '';
}
