{ config, inputs, pkgs, lib, stdenv, ... }:

{
  # List services that you want to enable:

  #shutdown faster
  systemd = {
    settings.Manager = {
      DefaultTimeoutStopSec = "10s";
    };
    user.extraConfig = ''DefaultTimeoutStopSec=10s'';

    #fix polkit howdy
    services."polkit-agent-helper@" = {
      serviceConfig = {
        DeviceAllow = "char-video4linux rw";
        PrivateDevices = "no";
      };
    };

    #nowait
    services.NetworkManager-wait-online.enable = false;
    #this adds like half a second to boot time
    oomd.enable = false;

    services.libvirtd = {
      enable = true;
      wantedBy = lib.mkForce [];
    };
  };

  #systemd stuffs
  #ssd thing or somthing
  services = {
    fstrim.enable = true;
  };
}
