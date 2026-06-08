{ config, pkgs, lib, ... }:

let
  oxygenVolumeSound = "${pkgs.kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo/audio-volume-change.ogg";
in {
  home.packages = with pkgs; [
    swaybg
    avizo
  ];

  xdg.configFile."hypr/scripts/change_wallpaper.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      WORKSPACE=$1
      WP_DIR="$HOME/Pictures/Wallpapers"

      case "$WORKSPACE" in
        1) WP="$WP_DIR/workspace-1.png" ;;
        2) WP="$WP_DIR/workspace-2.png" ;;
        3) WP="$WP_DIR/workspace-3.png" ;;
        *) WP="$WP_DIR/workspace-1.png" ;;
      esac

      if [ ! -f "$WP" ]; then
        WP="$WP_DIR/default.png"
      fi

      if [ -f "$WP" ]; then
        pkill -x swaybg || true
        swaybg -i "$WP" -m fill &
      fi
    '';
  };

  xdg.configFile."hypr/scripts/wallpaper_init.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      ~/.config/hypr/scripts/change_wallpaper.sh 1
    '';
  };

  xdg.configFile."hypr/scripts/focus_workspace.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      WS="$1"
      hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = ''${WS} }))"
      ~/.config/hypr/scripts/change_wallpaper.sh "$WS"
    '';
  };

  xdg.configFile."hypr/scripts/toggle_trackpad.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      TRACKPAD=$(hyprctl devices -j | jq -r '.mice[] | select(.name | test("touchpad|trackpad"; "i")) | .name' | head -n 1)
      if [ -z "$TRACKPAD" ]; then
        notify-send "Trackpad" "No touchpad found"
        exit 1
      fi

      STATE_FILE="$XDG_RUNTIME_DIR/hypr-trackpad-enabled"
      if [ ! -f "$STATE_FILE" ]; then
        echo "1" > "$STATE_FILE"
      fi

      if [ "$(cat "$STATE_FILE")" = "1" ]; then
        hyprctl eval "hl.device({ name = \"''${TRACKPAD}'\", enabled = false })"
        echo "0" > "$STATE_FILE"
        notify-send "Trackpad" "Disabled"
      else
        hyprctl eval "hl.device({ name = \"''${TRACKPAD}'\", enabled = true })"
        echo "1" > "$STATE_FILE"
        notify-send "Trackpad" "Enabled"
      fi
    '';
  };

  xdg.configFile."hypr/scripts/show_desktop.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      TMP_FILE="$XDG_RUNTIME_DIR/hyprland-show-desktop"
      CURRENT_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | .activeWorkspace.name')

      if [ -s "$TMP_FILE-$CURRENT_WORKSPACE" ]; then
        mapfile -t ADDRESS_ARRAY < "$TMP_FILE-$CURRENT_WORKSPACE"
        CMDS=""
        for address in "''${ADDRESS_ARRAY[@]}"; do
          [ -n "$address" ] || continue
          CMDS+="dispatch movetoworkspacesilent name:$CURRENT_WORKSPACE,address:$address;"
        done
        hyprctl --batch "$CMDS"
        rm "$TMP_FILE-$CURRENT_WORKSPACE"
      else
        mapfile -t ADDRESS_ARRAY < <(hyprctl clients -j | jq -r --arg CW "$CURRENT_WORKSPACE" '.[] | select(.workspace.name == $CW) | .address')
        CMDS=""
        TMP_ADDRESS=""
        for address in "''${ADDRESS_ARRAY[@]}"; do
          [ -n "$address" ] || continue
          TMP_ADDRESS+="$address"$'\n'
          CMDS+="dispatch movetoworkspacesilent special:desktop,address:$address;"
        done
        [ -n "$CMDS" ] || exit 0
        hyprctl --batch "$CMDS"
        printf '%s' "$TMP_ADDRESS" | sed -e '/^$/d' > "$TMP_FILE-$CURRENT_WORKSPACE"
      fi
    '';
  };

  xdg.configFile."hypr/scripts/qt-popup.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      APPLET=''${1:-}
      case "$APPLET" in
        volume) PLASMOID="org.kde.plasma.volume" ;;
        bluetooth) PLASMOID="org.kde.plasma.bluetooth" ;;
        battery) PLASMOID="org.kde.plasma.battery" ;;
        network) PLASMOID="org.kde.plasma.networkmanagement" ;;
        clock) PLASMOID="org.kde.plasma.calendar" ;;
        *) exit 2 ;;
      esac

      if pgrep -af "plasmawindowed $PLASMOID" >/dev/null; then
        pkill -f "plasmawindowed $PLASMOID"
        exit 0
      fi

      plasmawindowed "$PLASMOID" &
    '';
  };

  xdg.configFile."hypr/scripts/media-feedback.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
    '';
  };

  xdg.configFile."avizo/config.ini".text = ''
    [default]
    background = rgba(30, 30, 46, 0.95)
    border-color = rgba(148, 226, 213, 0.9)
    bar-fg-color = rgba(148, 226, 213, 0.95)
    bar-bg-color = rgba(49, 50, 68, 0.9)
    border-radius = 12
    border-width = 2
    padding = 20
    y-offset = 0.12
    x-offset = 0.5
    time = 1.5
    fade-in = 0.15
    fade-out = 0.3
  '';

  xdg.configFile."hypr/scripts/screenshot-region.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      hyprshot -m region --output-folder "$HOME/Pictures/Screenshots"
    '';
  };
}
