{ config, inputs, pkgs, lib, stdenv, ... }:

{
  # List services that you want to enable:

  #shutdown faster
  systemd = {
    settings.Manager = {
      DefaultTimeoutStopSec = "10s";
    };

    # Howdy runs inside polkit-agent-helper via PAM. Upstream unit sandboxes
    # block the IR camera and Python (MDWE), so facial auth never reaches the
    # agent and privilege prompts in Dolphin / Partition Manager fail closed.
    services."polkit-agent-helper@" = {
      serviceConfig = {
        DeviceAllow = [ "char-video4linux rw" ];
        PrivateDevices = "no";
        MemoryDenyWriteExecute = "no";
        # Single assignment — a Nix list becomes multiple keys and systemd
        # keeps only the last (breaking the helper's AF_UNIX sockets).
        RestrictAddressFamilies = "AF_UNIX AF_NETLINK";
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
