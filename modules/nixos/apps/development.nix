{ config, pkgs, ... }:

{
  # Development tools and IDEs
  programs.java.enable = true;
  programs.java.package = pkgs.jdk21;

  environment.systemPackages = with pkgs; [
    vscode
    git
    neovim
    android-studio
    kicad-small
    blender
    arduino-ide
    kdePackages.umbrello
    gnumake
    gemini-cli
    antigravity
  ];
}
