{ config, pkgs, ... }:

{
  # Enable Polkit daemon system-wide
  security.polkit.enable = true;

  # Allow members of "wheel" (including user samm) to manage systemd units and perform power operations without interactive authentication.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        if (action.id == "org.freedesktop.systemd1.manage-units"
            || action.id == "org.freedesktop.login1.reboot"
            || action.id == "org.freedesktop.login1.power-off"
            || action.id == "org.freedesktop.login1.suspend"
            || action.id == "org.freedesktop.login1.hibernate") {
          return polkit.Result.YES;
        }
      }
    });
  '';


  # Ensure KDE Polkit authentication agent is installed
  environment.systemPackages = with pkgs; [
    kdePackages.polkit-kde-agent-1
  ];

  # Start the KDE Polkit agent for user sessions
  systemd.user.services.polkit-kde-agent = {
    description = "polkit-kde-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
    };
  };
}
