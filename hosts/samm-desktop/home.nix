{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/home/niri/default.nix
  ];

  home = {
    username = "samm";
    homeDirectory = "/home/samm";
    stateVersion = "25.11";

    packages = with pkgs; [
      brave
      brave-origin
      google-chrome
    ];
  };

  programs.home-manager.enable = true;
}
