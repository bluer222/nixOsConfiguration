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
    fusion360
    arduino-ide
    kdePackages.umbrello
    gnumake
    python3
    antigravity-ide-fhs
    kdePackages.konsole
    ntfs3g
    gpsd
    moonlight-qt
    gcc
    gh
    zed-editor-fhs
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.zcode
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.muse-code
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.grok-bot
    t3code
    t3code.desktop
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-cli
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.cursor-agent
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.copilot-cli
    opencode
    opencode-desktop
  ];
}
