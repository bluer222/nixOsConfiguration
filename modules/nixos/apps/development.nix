{ config, inputs, pkgs, ... }:

let
  opencode-cli-latest =
    inputs.nixpkgs-opencode.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode;
  opencode-desktop-fixed = pkgs.opencode-desktop.overrideAttrs (oldAttrs: {
    env = (oldAttrs.env or { }) // {
      OPENCODE_VERSION = oldAttrs.version;
    };
  });
in
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
    opencode-cli-latest
    opencode-desktop-fixed
  ];
}
