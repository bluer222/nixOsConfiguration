{ config, inputs, pkgs, lib, stdenv, ... }:

{
# List services that you want to enable:

#shutdown faster
systemd.extraConfig = ''DefaultTimeoutStopSec=10s'';
systemd.user.extraConfig = ''DefaultTimeoutStopSec=10s'';

  #systemd stuffs
    #ssd thing or somthing
  services.fstrim.enable = true;

  #systemd.services.systemd-timesyncd.before = lib.mkForce [];
   # systemd.services.systemd-timesyncd.after = ["graphical-session.target"];
    #systemd.services.systemd-timesyncd.wantedBy = lib.mkForce ["graphical-session.target"];

    #nowait
  systemd.services.NetworkManager-wait-online.enable = false;
    #this adds like half a second to boot time
  systemd.oomd.enable = false;

  #mcontrolcenter
services.dbus.packages = [ "${pkgs.mcontrolcenter}" ];
  systemd.services."mcontrolcenter.helper" = {
  serviceConfig = {
    Type = "dbus";
    BusName = "mcontrolcenter.helper";
    ExecStart = "${pkgs.mcontrolcenter}/libexec/mcontrolcenter-helper";
    User = "root";
  };
};
  #mcontrolcenter-ui
  systemd.user.services.mcontrolcenter-ui = {
    enable = true;
    description = "mcontrolcenter";
    after = ["graphical-session.target"];
        wantedBy = ["graphical-session.target"];
        serviceConfig = {
      Type = "simple";
            ExecStart = "${pkgs.mcontrolcenter}/bin/mcontrolcenter";
    };
  };
   #krunner daemon
  systemd.user.services.krunner = {
    enable = true;
    description = "krunner";
    after = ["graphical-session.target"];
        wantedBy = ["graphical-session.target"];    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kdePackages.plasma-workspace}/bin/krunner -d";
          User = "samm";
    };
  };
    #portmaster-ui
  systemd.user.services."portmaster-ui" = {
    enable = true;
    description = "portmaster ui";
    after = ["graphical-session.target"];
        wantedBy = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "/opt/safing/portmaster/portmaster-start notifier";
    };
  };
      #signal
  systemd.user.services."signal" = {
    enable = true;
    description = "signal";
    after = [ "graphical-session.target" ];
    wantedBy = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.signal-desktop}/bin/signal-desktop --start-in-tray";
    };
  };
  #dont let nginx hold up the boot
  #systemd.services.nginx.before = lib.mkForce [];
  #  systemd.services.nginx.after = lib.mkForce [ "graphical-session.target" ];
  #      systemd.services.nginx.wantedBy = lib.mkForce  [ "graphical-session.target" ];

  #attempt at portmaster autostart
  systemd.services.portmaster = {
    enable = true;
    description = "Run portmaster service as root";
    path = with pkgs; [ iptables ];
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ]; # Start after basic system services
    serviceConfig = {
      ExecStart =
        "/opt/safing/portmaster/portmaster-start core -- -devmode"; # Path to the executable
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "10";
      LockPersonality = "yes";
      MemoryDenyWriteExecute = "yes";
      NoNewPrivileges = "yes";
      PrivateTmp = "yes";
      PIDFile = "/opt/safing/portmaster/core-lock.pid";
      Environment = [ "LOGLEVEL=info" ];
      ProtectSystem = "true";
      ReadWritePaths = [ "/opt/safing/portmaster/" ];
      RestrictAddressFamilies = "AF_UNIX AF_NETLINK AF_INET AF_INET6";
      RestrictNamespaces = "yes";
      ProtectHome = "read-only";
      ProtectKernelTunables = "yes";
      ProtectKernelLogs = "yes";
      ProtectControlGroups = "yes";
      PrivateDevices = "yes";
      AmbientCapabilities =
        "cap_chown cap_kill cap_net_admin cap_net_bind_service cap_net_broadcast cap_net_raw cap_sys_module cap_sys_ptrace cap_dac_override cap_fowner cap_fsetid";
      CapabilityBoundingSet =
        "cap_chown cap_kill cap_net_admin cap_net_bind_service cap_net_broadcast cap_net_raw cap_sys_module cap_sys_ptrace cap_dac_override cap_fowner cap_fsetid";
      SystemCallArchitectures = "native";
      SystemCallFilter = "@system-service @module";
      SystemCallErrorNumber = "EPERM";
    };
  };

  systemd.services.libvirtd = {
    enable = true;
    wantedBy = lib.mkForce [];
  };
}
