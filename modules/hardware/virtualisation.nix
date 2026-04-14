{ config, pkgs, ... }:
{
  #add quemu
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  programs.virt-manager.enable = true;

  #waydroid
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;

  #docker
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker.daemon.settings.features.cdi = true;
  #virtualisation.docker.enableNvidia = true;
}
