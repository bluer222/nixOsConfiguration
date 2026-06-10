{ config, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.hyprshutdown
    pkgs.jq
    pkgs.libnotify
  ];

  environment.etc."hypr-logout.sh".text = ''
    #!/usr/bin/env bash
    set -uo pipefail

    # hyprshutdown sends proper close requests to every app, waits, then exits
    # Hyprland cleanly — greetd returns to the greeter.
    # Do NOT use loginctl terminate-session; that kills the session and causes a black screen.
    exec ${pkgs.hyprshutdown}/bin/hyprshutdown --no-fork
  '';
  environment.etc."hypr-logout.sh".mode = "0755";
}
