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

  # Secrets provider (Secret Service API for browsers etc.). Keyfile-only DB:
  # unlocks silently as long as keepassxc.ini remembers the keyfile association
  # (established on first manual open). Security boundary = the LUKS volume,
  # same as everything else in $HOME.
  systemd.user.services.keepassxc = {
    Unit = {
      Description = "KeePassXC (Secret Service provider)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.keepassxc}/bin/keepassxc %h/Passwords.kdbx";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
