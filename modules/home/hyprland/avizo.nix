{ config, pkgs, lib, ... }:

{
  # avizo-service needs a display — started from hyprland (avizo-start.sh).
  systemd.user.services.avizo = {
    Unit = {
      Description = "Avizo (disabled — started by Hyprland)";
      ConditionPathExists = "/nonexistent";
    };
    Service.ExecStart = "${pkgs.coreutils}/bin/false";
    Install.WantedBy = lib.mkForce [ ];
  };
}
