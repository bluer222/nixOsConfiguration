{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/home/hyprland/default.nix
  ];

  home = {
    username = "samm";
    homeDirectory = "/home/samm";
    stateVersion = "25.11";

    packages = with pkgs; [
      brave
    ];
  };

  programs.home-manager.enable = true;
}
