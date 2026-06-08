{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./hyprland.nix
    ./waybar.nix
    ./idle.nix
    ./theme.nix
    ./scripts.nix
  ];

  home.packages = with pkgs; [
    # Wayland basics
    wl-clipboard
    cliphist
    wdisplays
    jq

    # Waybar & Launchers
    waybar
    rofi
    networkmanagerapplet
    kdePackages.bluedevil
    kdePackages.plasma-pa
    kdePackages.plasma-workspace
    
    # Audio & Brightness
    kdePackages.oxygen-sounds
    brightnessctl
    
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
