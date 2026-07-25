{ config, pkgs, lib, ... }:
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

  #dont wait for online
  systemd.services.docker.after = lib.mkForce [ "network.target" "firewalld.service" ];
  systemd.services.docker.wants = lib.mkForce [ ];

  programs.virt-manager.enable = true;

  hardware.nvidia-container-toolkit.enable = true;
}
