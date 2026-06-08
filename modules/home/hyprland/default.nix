{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./hyprland.nix
    ./waybar.nix
    ./idle.nix
    ./theme.nix
    ./scripts.nix
    ./notifications.nix
    ./avizo.nix
  ];

  home.packages = with pkgs; [
    # Wayland basics
    wl-clipboard
    cliphist
    jq

    # Waybar & Launchers
    waybar
    rofi
    networkmanagerapplet
    kdePackages.bluedevil
    kdePackages.plasma-pa
    kdePackages.plasma-workspace
    kdePackages.systemsettings
    kdePackages.breeze-icons
    pulseaudio

    # Audio, brightness OSD, and feedback
    kdePackages.oxygen-sounds
    avizo
    brightnessctl
    libnotify
    
    # Idle & Lock
    hypridle
    hyprlock
    hyprpolkitagent

    # Screenshot
    grim
    slurp
    swappy
  ];
}
