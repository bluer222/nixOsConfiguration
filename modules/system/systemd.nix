{ config, inputs, pkgs, lib, stdenv, ... }:

{
  # List services that you want to enable:

  #shutdown faster
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
  };
  systemd.user.extraConfig = ''DefaultTimeoutStopSec=10s'';

  #systemd stuffs
  #ssd thing or somthing
  services.fstrim.enable = true;

  services.portmaster = {
    enable = true;
    settings.devmode = true;  # UI at 127.0.0.1:817
  };

  #fix polkit howdy
  systemd.services."polkit-agent-helper@".serviceConfig = {
    DeviceAllow = "char-video4linux rw";
    PrivateDevices = "no";
  };

  #nowait
  systemd.services.NetworkManager-wait-online.enable = false;
  #this adds like half a second to boot time
  systemd.oomd.enable = false;

  systemd.services.libvirtd = {
    enable = true;
    wantedBy = lib.mkForce [];
  };
}
