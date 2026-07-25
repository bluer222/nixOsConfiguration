{ pkgs, ... }:

{
  # Qt notification daemon with working action buttons (replaces mako).
  # Appearance largely follows the LXQt/Qt theme; placement/timeout tuned here.
  xdg.configFile."lxqt/notifications.conf".text = ''
    [General]
    placement=top-right
    width=360
    spacing=10
    server_decides=8
    unattendedMaxNum=5
    doNotDisturb=false
    screenWithMouse=false
  '';

  systemd.user.services.lxqt-notificationd = {
    Unit = {
      Description = "LXQt notification daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.lxqt.lxqt-notificationd}/bin/lxqt-notificationd";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = [
    pkgs.lxqt.lxqt-notificationd
    pkgs.libnotify
  ];
}
