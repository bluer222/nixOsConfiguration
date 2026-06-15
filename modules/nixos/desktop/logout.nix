{ config, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.hyprshutdown
    pkgs.jq
    pkgs.libnotify
    pkgs.wleave
  ];

  services.logind.settings.Login.HandlePowerKey = "ignore";
  services.logind.settings.Login.HandleLidSwitch = "ignore";


}
