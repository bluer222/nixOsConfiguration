{ config, pkgs, ... }:

{
  environment.etc."hypr-logout.sh".text = ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Browsers block session end waiting for "close tabs?" dialogs.
    pkill -TERM -f '(^|/)brave($|[[:space:]])|brave-browser|chromium|google-chrome' 2>/dev/null || true
    sleep 0.5
    pkill -KILL -f '(^|/)brave($|[[:space:]])|brave-browser|chromium|google-chrome' 2>/dev/null || true

    # Exit hyprland cleanly; plasma-login-manager returns to greeter.
    if command -v hyprctl >/dev/null 2>&1; then
      hyprctl dispatch exit
    elif [ -n "''${XDG_SESSION_ID:-}" ]; then
      loginctl terminate-session "''${XDG_SESSION_ID}" --force
    fi
  '';
  environment.etc."hypr-logout.sh".mode = "0755";
}
