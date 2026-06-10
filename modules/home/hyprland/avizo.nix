{ config, pkgs, ... }:

{
  systemd.user.services.avizo = {
    Unit = {
      Description = "Avizo volume/brightness notification service";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.avizo}/bin/avizo-service";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };
}
