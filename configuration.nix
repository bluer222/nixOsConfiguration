# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, inputs, pkgs, lib, stdenv, ... }:

{
  imports = [
    # Hardware and boot configuration
    ./modules/boot.nix
    ./modules/gpu.nix
    ./modules/hardware/kernel.nix
    ./modules/hardware/power.nix
    ./modules/hardware/virtualisation.nix

    # System core settings
    ./modules/system/core.nix
    ./modules/system/shell.nix
    ./modules/system/audio.nix
    ./modules/system/desktop.nix
    ./modules/system/systemd.nix

    # Networking services
    ./modules/networking/core.nix
    ./modules/networking/nginx.nix
    ./modules/networking/avahi.nix

    # System services
    ./modules/services/printing.nix
    ./modules/services/vr.nix

    # Home Manager modules
    ./home/modules/user.nix
    ./home/modules/base.nix
    ./home/modules/apps/gaming.nix
    ./home/modules/apps/multimedia.nix
    ./home/modules/apps/development.nix
    ./home/modules/apps/utilities.nix
    ./home/modules/apps/security.nix
    ./home/modules/apps/desktops/kde.nix
  ];

  # Nix cache configuration
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://comfyui.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    trusted-users = [ "root" "samm" ];
    system-features = [ "gccarch-raptorlake" ];
    warn-dirty = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
