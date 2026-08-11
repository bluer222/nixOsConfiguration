{ pkgs, ... }:

let
  nerdFont = pkgs."nerd-fonts".fira-code;
in {
  imports = [
    ./settings.nix
    ./idle.nix
    ./waybar.nix
    ./theme.nix
    ./notifications.nix
    ./session-services.nix
    ./wleave.nix
    ./cliphist.nix
  ];

  services.avizo.enable = true;

  home.packages = with pkgs; [
    wl-clipboard
    jq
    xdg-utils
    libxcb-cursor

    waybar
    rofi
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
    nerdFont

    swayidle
    swaylock
    swaybg
    grim
    slurp
    tesseract
    niri-helper
    xwayland-satellite
    hyprpwcenter
  ];

  home.sessionVariables = { };

  systemd.user.startServices = "sd-switch";
}
