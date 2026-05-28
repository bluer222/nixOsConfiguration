{ config, pkgs, ... }:
{
  #add quemu
  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;

    #waydroid
    waydroid = {
      enable = true;
      package = pkgs.waydroid-nftables;
    };

    #docker
    docker = {
      enable = true;
      daemon.settings.features.cdi = true;
      #enableNvidia = true;
    };
  };

  programs.virt-manager.enable = true;

  hardware.nvidia-container-toolkit.enable = true;
}
