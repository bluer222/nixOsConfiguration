{ config, pkgs, ... }:

{
  systemd.user.services.avizo = {
    description = "Avizo volume/brightness notification service";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.avizo}/bin/avizo-service";
      Restart = "on-failure";
    };
  };
}
