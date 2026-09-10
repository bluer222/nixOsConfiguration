{ config, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.jq
    pkgs.libnotify
  ];

  services.logind.settings.Login.HandlePowerKey = "ignore";
  services.logind.settings.Login.HandleLidSwitch = "suspend";
  services.logind.settings.Login.InhibitDelayMaxSec = "15s";
}
