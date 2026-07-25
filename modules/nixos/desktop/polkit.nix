{ config, pkgs, ... }:

{
  security.polkit.enable = true;

  # Dolphin "Open as Administrator" / privileged file ops go through kio-admin + polkit.
  environment.systemPackages = with pkgs; [
    kdePackages.kio-admin
  ];
}
