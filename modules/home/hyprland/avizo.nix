{ config, pkgs, ... }:

{
  systemd.user.services.avizo = {
    Unit = {
      Description = "Avizo volume/brightness notification service";
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.avizo}/bin/avizo-service";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
