{ config, pkgs, ... }:

{
  # Gaming and VR related packages
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    dedicatedServer.openFirewall = true;
    #use igpu
    package = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        intel-vaapi-driver
        libva
        libvdpau-va-gl
        vulkan-loader
        vulkan-tools
        mesa
        intel-media-driver
      ];
    };
  };
  programs.steam.protontricks.enable = true;

  environment.systemPackages = with pkgs; [
    steam
    lutris
    godot_4
    proton-vpn
    mangohud
    winetricks
    wayvr
  ];
}
