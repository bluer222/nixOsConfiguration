{ pkgs, ... }:

{
  imports = [
    ./settings.nix
    ./noctalia.nix
    ./theme.nix
    ./session-services.nix
  ];

  home.packages = with pkgs; [
    wl-clipboard
    jq
    xdg-utils
    libxcb-cursor

    kdePackages.dolphin
    kdePackages.qtsvg
    kdePackages.kio
    kdePackages.kio-extras
    kdePackages.kio-fuse

    kdePackages.kded

    libsecret
    nerd-fonts.fira-code

    niri-helper
    xwayland-satellite
    hyprpicker
    brightnessctl
    kdePackages.kactivitymanagerd

    wl-kbptr
  ];

  # Bisect-only selection; Enter/Space then clicks the fetched option.
  # Needs niri's wlr-layer-shell + wlr-virtual-pointer support.
  xdg.configFile."wl-kbptr/config".text = ''
    [general]
    # Bisect down to an area, then click its center. Mid-bisect, g/h/b are
    # left/right/middle click (the tool's fixed home-row set, layout-mapped).
    modes=bisect,click
  '';

  home.sessionVariables = {
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GTK_CSD = "0";
  };

  systemd.user.startServices = "sd-switch";
}
