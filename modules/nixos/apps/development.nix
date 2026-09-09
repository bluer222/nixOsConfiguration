{ config, inputs, pkgs, ... }:

{
  # Development tools and IDEs
  programs.java.enable = true;
  programs.java.package = pkgs.jdk21;

  environment.systemPackages = with pkgs; [
    vscode
    git
    neovim
    android-studio
    kicad
    blender
    arduino-ide
    kdePackages.umbrello
    gnumake
    cursor-cli
    python3
    antigravity-ide-fhs
    antigravity-cli
    kdePackages.konsole
    ntfs3g
    gpsd
    github-copilot-cli
    moonlight-qt
    opencode
    opencode-desktop
    gcc
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.zcode
  ];
}
