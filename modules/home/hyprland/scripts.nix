{ config, pkgs, lib, ... }:

let
  volumeSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/audio-volume-change.oga";
  oxygenPowerSound = "${pkgs.kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo/power-plug.ogg";
  oxygenUnplugSound = "${pkgs.kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo/power-unplug.ogg";
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
    '';
  };

  xdg.configFile."hypr/scripts/show_desktop.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      STATE_FILE="$XDG_RUNTIME_DIR/hyprland-show-desktop"

      if [ -f "$STATE_FILE" ]; then
        hyprctl eval "hl.config({ decoration = { blur = { enabled = true } } })"
        while read -r addr; do
          [ -n "''${addr}" ] && hyprctl dispatch setprop "address:''${addr}" alpha 1
        done < <(hyprctl clients -j | ${pkgs.jq}/bin/jq -r '.[] | select(.mapped == true) | .address')
        rm "$STATE_FILE"
      else
        hyprctl eval "hl.config({ decoration = { blur = { enabled = false } } })"
        while read -r addr; do
          [ -n "''${addr}" ] && hyprctl dispatch setprop "address:''${addr}" alpha 0.15
        done < <(hyprctl clients -j | ${pkgs.jq}/bin/jq -r '.[] | select(.mapped == true) | .address')
        touch "$STATE_FILE"
      fi
    '';
  };

  xdg.configFile."hypr/scripts/popup-closer.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -uo pipefail

      socket_path() {
        printf '%s/hypr/%s/.socket2.sock' "''${XDG_RUNTIME_DIR:?}" "''${HYPRLAND_INSTANCE_SIGNATURE:?}"
      }

      until [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -S "$(socket_path)" ]; do
        sleep 1
      done

      close_plasma_popups() {
        hyprctl eval 'hl.dispatch(hl.dsp.window.close({ window = "class:org.kde.plasmawindowed" }))' >/dev/null 2>&1 || true
      }

      while true; do
        ${pkgs.socat}/bin/socat -U - "UNIX-CONNECT:$(socket_path)" | while read -r line; do
          case "''${line}" in
            activewindow\>\>*)
              cls="''${line#activewindow>>}"
              cls="''${cls%%,*}"
              if [[ "''${cls}" != org.kde.plasmawindowed* ]]; then
                close_plasma_popups
              fi
              ;;
            activewindowv2\>\>*)
              cls=$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.class // empty')
              if [[ "''${cls}" != org.kde.plasmawindowed* ]]; then
                close_plasma_popups
              fi
              ;;
          esac
        done
        sleep 1
      done
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
        notifications) PLASMOID="org.kde.plasma.notifications" ;;
        *) exit 2 ;;
      esac

      if pgrep -af "plasmawindowed.*''${PLASMOID}" >/dev/null 2>&1; then
        pkill -f "plasmawindowed.*''${PLASMOID}"
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
      ${pkgs.pipewire}/bin/paplay "${volumeSound}" &
    '';
  };

  xdg.configFile."hypr/scripts/brightness-key.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      case "$1" in
        up) lightctl -d up ;;
        down) lightctl -d down ;;
        *) exit 2 ;;
      esac
    '';
  };

  xdg.configFile."hypr/scripts/wallpaper-watcher.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -uo pipefail

      socket_path() {
        printf '%s/hypr/%s/.socket2.sock' "''${XDG_RUNTIME_DIR:?}" "''${HYPRLAND_INSTANCE_SIGNATURE:?}"
      }

      until [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -S "$(socket_path)" ]; do
        sleep 1
      done

      last=""
      while true; do
        ${pkgs.socat}/bin/socat -U - "UNIX-CONNECT:$(socket_path)" | while read -r line; do
          case "''${line}" in
            workspace\>\>*|workspacev2\>\>*|focusedmon\>\>*|focusedmonv2\>\>*)
              ws=$(hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.id')
              if [ -n "''${ws}" ] && [ "''${ws}" != "''${last}" ]; then
                last="''${ws}"
                "$HOME/.config/hypr/scripts/change_wallpaper.sh" "''${ws}"
              fi
              ;;
          esac
        done
        sleep 1
      done
    '';
  };

  xdg.configFile."hypr/scripts/power-sounds.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      LAST_STATE_FILE="''${XDG_RUNTIME_DIR}/hypr-power-online"
      PLUG_SOUND="${oxygenPowerSound}"
      UNPLUG_SOUND="${oxygenUnplugSound}"

      get_online() {
        for supply in /sys/class/power_supply/*; do
          [ -f "''${supply}/online" ] || continue
          cat "''${supply}/online"
          return 0
        done
        echo 0
      }

      play_sound() {
        ${pkgs.pipewire}/bin/paplay "''${1}" &
      }

      CURRENT="''$(get_online)"
      echo "''${CURRENT}" > "''${LAST_STATE_FILE}"

      udevadm monitor --subsystem-match=power_supply --property | while read -r line; do
        case "''${line}" in
          *"POWER_SUPPLY_ONLINE="*)
            NEW="''${line#*=}"
            OLD="''$(cat "''${LAST_STATE_FILE}" 2>/dev/null || echo "''${CURRENT}")"
            if [ "''${NEW}" != "''${OLD}" ]; then
              if [ "''${NEW}" = "1" ]; then
                play_sound "''${PLUG_SOUND}"
              else
                play_sound "''${UNPLUG_SOUND}"
              fi
              echo "''${NEW}" > "''${LAST_STATE_FILE}"
            fi
            ;;
        esac
      done
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
