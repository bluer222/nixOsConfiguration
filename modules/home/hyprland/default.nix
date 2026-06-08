{ config, pkgs, inputs, ... }:

{
  imports = [
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
    rofi-wayland
    
    # Idle & Lock
    hypridle
    hyprlock

    # Screenshot
    spectacle
  ];
}
