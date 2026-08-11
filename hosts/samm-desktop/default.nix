{ config, inputs, pkgs, lib, stdenv, ... }:

{
  imports = [
    ./hardware.nix

    # Hardware and boot configuration
    ../../modules/nixos/boot.nix
    ../../modules/nixos/hardware/gpu.nix
    ../../modules/nixos/hardware/kernel.nix
    ../../modules/nixos/hardware/power.nix
    ../../modules/nixos/hardware/virtualisation.nix

    # System core settings
    ../../modules/nixos/system/core.nix
    ../../modules/nixos/system/shell.nix
    ../../modules/nixos/system/audio.nix
    ../../modules/nixos/desktop/core.nix
    ../../modules/nixos/desktop/portals.nix
    ../../modules/nixos/desktop/polkit.nix
    ../../modules/nixos/desktop/logout.nix
    ../../modules/nixos/system/performance.nix
    ../../modules/nixos/desktop/niri.nix
    ../../modules/nixos/system/systemd.nix

    # Networking services
    ../../modules/nixos/networking/core.nix
    ../../modules/nixos/networking/nginx.nix
    ../../modules/nixos/networking/avahi.nix
    ../../modules/nixos/networking/portmaster.nix

    # System services
    ../../modules/nixos/services/printing.nix
    ../../modules/nixos/services/vr.nix
    ../../modules/nixos/services/uresourced.nix
    ../../modules/nixos/services/lact.nix

    # User and App configurations
    ../../modules/nixos/user.nix
    ../../modules/nixos/base-environment.nix
    ../../modules/nixos/apps/gaming.nix
    ../../modules/nixos/apps/multimedia.nix
    ../../modules/nixos/apps/development.nix
    ../../modules/nixos/apps/utilities.nix
    ../../modules/nixos/apps/security.nix
    ../../modules/nixos/apps/kde-extras.nix
  ];

  # Nix cache configuration
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://comfyui.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
    trusted-users = [ "root" "samm" ];
    system-features = [ "gccarch-raptorlake" ];
    warn-dirty = false;
  };

  system.stateVersion = "24.05";
}
