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
  # --pw-stdin feeds an empty password so the unlock dialog never appears;
  # the keyfile association comes from keepassxc.ini. Security boundary = the
  # LUKS volume, same as everything else in $HOME.
  systemd.user.services.keepassxc =
    let
      unlockScript = pkgs.writeShellScript "keepassxc-autounlock" ''
        # DB password lives here by design: security boundary is the LUKS
        # volume, same as the keyfile and everything else in $HOME.
        # KeePassXC refuses piped stdin for credentials unless a TTY exists,
        # hence the script(1) pty wrapper; xcb backend per upstream docs.
        printf '%s\n' 'dj2#9(jd@10' | ${pkgs.util-linux}/bin/script -qec \
          "env QT_QPA_PLATFORM=xcb ${pkgs.keepassxc}/bin/keepassxc --minimized --keyfile $HOME/Passwords.keyx --pw-stdin $HOME/Passwords.kdbx" \
          /dev/null
      '';
    in
    {
      Unit = {
        Description = "KeePassXC (Secret Service provider)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${unlockScript}";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "niri.service" ];
    };
}
