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
    kdePackages.kwallet
    kdePackages.kwallet-pam
    kdePackages.kwalletmanager

    libsecret
    nerd-fonts.fira-code

    niri-helper
    xwayland-satellite
    hyprpicker
    brightnessctl
    kdePackages.kactivitymanagerd
  ];

  home.sessionVariables = {
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GTK_CSD = "0";
  };

  systemd.user.startServices = "sd-switch";
}
