{ pkgs, ... }:

{
  systemd.user.services.niri-helper = {
    Unit = {
      Description = "Niri session helper daemon (wallpaper, idle dim, power, binds)";
      PartOf = [ "graphical-session.target" ];
      After = [
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

  systemd.user.services.kwalletd6 = {
    Unit = {
      Description = "KDE Wallet daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.kwallet}/bin/kwalletd6";
      Restart = "on-failure";
      RestartSec = 3;
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
      ExecStart = "${pkgs.kdePackages.kactivitymanagerd}/bin/kactivitymanagerd";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
