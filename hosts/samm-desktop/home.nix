{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home/hyprland/default.nix
  ];

  home = {
    username = "samm";
    homeDirectory = "/home/samm";
    stateVersion = "25.11";

    packages = with pkgs; [
      # Add user-specific packages here
    ];

    sessionVariables = {
      # EDITOR = "vim";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
