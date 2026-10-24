{ pkgs, ... }:

{
  # Isolate Fusion's niri popup-drag workaround from other X11 applications.
  systemd.user.services.fusion360-xwayland = {
    Unit = {
      Description = "Xwayland bridge for Fusion 360";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      Type = "notify";
      ExecStart = "${pkgs.xwayland-satellite-fusion}/bin/xwayland-satellite :1";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "niri.service" ];
  };

  systemd.user.services.niri-helper = {
    Unit = {
      Description = "Niri session helper daemon (wallpaper, idle dim, power, binds)";
      PartOf = [ "graphical-session.target" "niri.service" ];
      BindsTo = [ "niri.service" ];
      After = [
        "niri.service"
        "graphical-session.target"
        "noctalia.service"
        "pipewire.service"
        "wireplumber.service"
      ];
      Wants = [
        "noctalia.service"
        "pipewire.service"
        "wireplumber.service"
      ];
    };
    Service = {
      ExecStart = "${pkgs.niri-helper}/bin/niri-helper daemon";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };

  # Dolphin "Recent Files" / places history needs the activity manager.
  systemd.user.services.kactivitymanagerd = {
    Unit = {
      Description = "KDE Activity Manager";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      # Binary lives in libexec/, not bin/, since the KDE 6 packaging change.
      ExecStart = "${pkgs.kdePackages.kactivitymanagerd}/libexec/kactivitymanagerd";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
