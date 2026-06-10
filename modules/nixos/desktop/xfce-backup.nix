{ config, pkgs, ... }:

{
  # Minimal XFCE backup session — panel + wm only, no Thunar or bundled apps.
  services.xserver.enable = true;

  environment.systemPackages = with pkgs; [
    xfce4-session
    xfce4-panel
    xfwm4
    xfce4-settings
    xfconf
    garcon
  ];
}
