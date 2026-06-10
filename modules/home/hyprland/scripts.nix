{ config, pkgs, lib, ... }:

let
  # oxygen-sounds no longer ships audio-volume-change; message-lowpriority is a short UI tick
  volumeSound = "${pkgs.kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo/message-lowpriority.ogg";
  oxygenPowerSound = "${pkgs.kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo/power-plug.ogg";
  oxygenUnplugSound = "${pkgs.kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo/power-unplug.ogg";
  sessionStateDir = "${config.xdg.dataHome}/hyprland";
in {
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
      esac

      if [ ! -f "$WP" ]; then
        exit 0
      fi

      if [ -f "$WP" ]; then
        ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper ", $WP"
      fi
    '';
  };

  # greetd sets PAM_KWALLET5_LOGIN on the Hyprland process only — not in systemd.
  # Do not kill running kwallet/ksecretd: greetd PAM starts ksecretd --pam-login to unlock.
  xdg.configFile."hypr/scripts/kwallet-unlock.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      kwallet_open() {
        ${pkgs.systemd}/bin/busctl --user call \
          org.kde.kwalletd6 /modules/kwalletd5 org.kde.KWallet isOpen s kdewallet \
          2>/dev/null | grep -q true
      }

      if kwallet_open; then
        systemctl --user start ksecretd.service 2>/dev/null || true
        exit 0
      fi

      systemctl --user reset-failed kwalletd6.service 2>/dev/null || true
      if ! ${pkgs.systemd}/bin/busctl --user status org.kde.kwalletd6 &>/dev/null; then
        systemctl --user start kwalletd6.service
      fi

      for _ in $(seq 1 50); do
        ${pkgs.systemd}/bin/busctl --user status org.kde.kwalletd6 &>/dev/null && break
        sleep 0.1
      done

      # PAM handoff while greetd's kwallet5.socket is still live.
      if [[ -n "''${PAM_KWALLET5_LOGIN:-}" ]]; then
        ${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init || true
      fi

      # Wait for greetd's ksecretd --pam-login child to finish unlocking.
      for _ in $(seq 1 50); do
        kwallet_open && break
        sleep 0.1
      done

      systemctl --user import-environment PAM_KWALLET5_LOGIN 2>/dev/null || true
      systemctl --user start ksecretd.service 2>/dev/null || true
    '';
  };

  xdg.configFile."hypr/scripts/session-resume.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -uo pipefail

      for _ in $(seq 1 30); do
        [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -n "''${WAYLAND_DISPLAY:-}" ] && break
        sleep 0.2
      done

      hyprctl eval 'hl.dispatch(hl.dsp.dpms({ action = "on" }))' 2>/dev/null || true

      "$HOME/.config/hypr/scripts/kwallet-unlock.sh" 2>/dev/null || true

      systemctl --user restart plasma-kded6.service 2>/dev/null || true
      systemctl --user restart powerdevil.service 2>/dev/null || true
      systemctl --user restart plasma-xdg-desktop-portal-kde.service 2>/dev/null || true
      systemctl --user restart xdg-desktop-portal.service 2>/dev/null || true
      systemctl --user restart hyprpaper.service 2>/dev/null || true

      pkill -f "plasmawindowed" 2>/dev/null || true

      (
        ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental
      ) &

      systemctl --user restart hyprpolkitagent.service 2>/dev/null || true
    '';
  };

  xdg.configFile."hypr/scripts/focus_workspace.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      rm -f "$XDG_RUNTIME_DIR/hyprland-show-desktop"
      WS="$1"
      hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = ''${WS} }))"
    '';
  };

  xdg.configFile."hypr/scripts/show_desktop.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Show desktop by switching to workspace 4 (empty desk; windows stay put).
      set -uo pipefail

      STATE_FILE="$XDG_RUNTIME_DIR/hyprland-show-desktop"
      DESKTOP_WS=4

      current=$(hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.id')

      if [ -f "$STATE_FILE" ] || [ "$current" = "$DESKTOP_WS" ]; then
        if [ -f "$STATE_FILE" ]; then
          saved=$(cat "$STATE_FILE")
          rm -f "$STATE_FILE"
          hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = ''${saved} }))"
        elif [ "$current" = "$DESKTOP_WS" ]; then
          rm -f "$STATE_FILE"
          hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = 1 }))"
        fi
      else
        echo "$current" > "$STATE_FILE"
        hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = ''${DESKTOP_WS} }))"
      fi
    '';
  };

  xdg.configFile."hypr/scripts/volume-key.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -uo pipefail
      case "$1" in
        up) volumectl -d up ;;
        down) volumectl -d down ;;
        mute) volumectl -d toggle-mute ;;
        *) exit 2 ;;
      esac
      ${pkgs.wireplumber}/bin/pw-play "${volumeSound}" >/dev/null 2>&1 &
    '';
  };

  xdg.configFile."hypr/scripts/brightness-dim.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      STATE_FILE="$XDG_RUNTIME_DIR/hypr-brightness-saved"
      if [ ! -f "$STATE_FILE" ]; then
        bl="/sys/class/backlight/intel_backlight"
        [ -d "$bl" ] || bl=$(echo /sys/class/backlight/* | awk '{print $1}')
        if [ -r "$bl/brightness" ] && [ -r "$bl/max_brightness" ]; then
          cur=$(cat "$bl/brightness")
          max=$(cat "$bl/max_brightness")
          pct=$((cur * 100 / max))
          echo "$pct" > "$STATE_FILE"
          lightctl -d set =10%
        fi
      fi
    '';
  };

  xdg.configFile."hypr/scripts/brightness-restore.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      STATE_FILE="$XDG_RUNTIME_DIR/hypr-brightness-saved"
      if [ -f "$STATE_FILE" ]; then
        lightctl -d set "=$(cat "$STATE_FILE")%"
        rm "$STATE_FILE"
      fi
    '';
  };

  xdg.configFile."hypr/scripts/session-save.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      mkdir -p "${sessionStateDir}"
      hyprctl clients -j | ${pkgs.jq}/bin/jq -c '
        [ .[]
          | select(.mapped == true and .class != "org.kde.plasmawindowed")
          | { class, title, workspace: .workspace.id, floating, at, size }
        ]
      ' > "${sessionStateDir}/session.json"
    '';
  };

  xdg.configFile."hypr/scripts/session-restore.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -uo pipefail

      SESSION_FILE="${sessionStateDir}/session.json"
      [ -f "$SESSION_FILE" ] || exit 0

      declare -A CLASS_CMD=(
        [brave-browser]="brave"
        [Brave-browser]="brave"
        [code]="code"
        [Code]="code"
        [cursor]="cursor"
        [Cursor]="cursor"
        [org.signal.Signal]="signal-desktop"
        [org.kde.dolphin]="dolphin"
        [Alacritty]="alacritty"
        [kitty]="kitty"
        [foot]="foot"
      )

      sleep 2

      while IFS= read -r entry; do
        class=$(echo "$entry" | ${pkgs.jq}/bin/jq -r '.class')
        ws=$(echo "$entry" | ${pkgs.jq}/bin/jq -r '.workspace')
        cmd="''${CLASS_CMD[$class]:-}"

        if [ -z "$cmd" ]; then
          continue
        fi

        if ! hyprctl clients -j | ${pkgs.jq}/bin/jq -e --arg c "$class" '.[] | select(.class == $c)' >/dev/null; then
          hyprctl eval "hl.dispatch(hl.dsp.exec_cmd(\"[workspace ''${ws} silent] ''${cmd}\"))"
        fi
      done < <(${pkgs.jq}/bin/jq -c '.[]' "$SESSION_FILE")
    '';
  };

  xdg.configFile."hypr/scripts/gtk-apps-report.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "GTK-dependent packages in current system closure:"
      echo "=================================================="

      nix-store -qR /run/current-system 2>/dev/null | while read -r storepath; do
        if nix-store -qR "$storepath" 2>/dev/null | grep -qE '/gtk[34]?-'; then
          pkgname=$(basename "$storepath" | sed 's/-[^-]*-[^-]*$//')
          echo "$pkgname"
        fi
      done | sort -u
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

      close_other_plasma_popups() {
        active_addr=$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.address // empty')
        hyprctl clients -j | ${pkgs.jq}/bin/jq -r --arg keep "$active_addr" '
          .[]
          | select(.class | startswith("org.kde.plasmawindowed"))
          | select(.address != $keep)
          | .address
        ' | while read -r addr; do
          [ -n "$addr" ] || continue
          hyprctl eval "hl.dispatch(hl.dsp.window.close({ window = \"address:''${addr}\" }))" >/dev/null 2>&1 || true
        done
      }

      while true; do
        ${pkgs.socat}/bin/socat -U - "UNIX-CONNECT:$(socket_path)" | while read -r line; do
          case "''${line}" in
            activewindow\>\>*|activewindowv2\>\>*)
              cls=$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.class // empty')
              if [[ "''${cls}" == org.kde.plasmawindowed* ]]; then
                close_other_plasma_popups
              else
                close_plasma_popups
              fi
              ;;
          esac
        done
        sleep 1
      done
    '';
  };

  xdg.configFile."hypr/scripts/mako-copy.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      id="''${1:-}"
      [ -n "$id" ] || exit 1

      text=$(${pkgs.mako}/bin/makoctl list -n "$id" 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r '.data.body.data // .data.summary.data // empty' 2>/dev/null)
      [ -n "$text" ] || exit 0
      printf '%s' "$text" | ${pkgs.wl-clipboard}/bin/wl-copy
      ${pkgs.libnotify}/bin/notify-send -a mako -t 1500 "Copied notification text"
    '';
  };

  xdg.configFile."hypr/scripts/open-monitors.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      pick=$(${pkgs.hyprland}/bin/hyprctl monitors -j \
        | ${pkgs.jq}/bin/jq -r '.[] | "\(.name)\t\(.description // .name)  \(.width)x\(.height)@\(.refreshRate)Hz  scale \(.scale)"' \
        | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Monitor" -theme ~/.config/rofi/spotlight.rasi \
        | cut -f1)

      [ -n "$pick" ] || exit 0

      action=$(${pkgs.rofi}/bin/rofi -dmenu -i -p "''${pick}" -theme ~/.config/rofi/spotlight.rasi <<'EOF'
      Scale 1.0
      Scale 1.25
      Scale 1.5
      Scale 1.75
      Scale 2.0
      Preferred mode (auto)
      Disable monitor
      Enable monitor (preferred)
      EOF
      )

      [ -n "$action" ] || exit 0

      case "$action" in
        "Scale 1.0")   ${pkgs.hyprland}/bin/hyprctl keyword monitor "''${pick},preferred,auto,1" ;;
        "Scale 1.25")  ${pkgs.hyprland}/bin/hyprctl keyword monitor "''${pick},preferred,auto,1.25" ;;
        "Scale 1.5")   ${pkgs.hyprland}/bin/hyprctl keyword monitor "''${pick},preferred,auto,1.5" ;;
        "Scale 1.75")  ${pkgs.hyprland}/bin/hyprctl keyword monitor "''${pick},preferred,auto,1.75" ;;
        "Scale 2.0")   ${pkgs.hyprland}/bin/hyprctl keyword monitor "''${pick},preferred,auto,2" ;;
        "Preferred mode (auto)") ${pkgs.hyprland}/bin/hyprctl keyword monitor "''${pick},preferred,auto,1" ;;
        "Disable monitor") ${pkgs.hyprland}/bin/hyprctl keyword monitor "''${pick},disable" ;;
        "Enable monitor (preferred)") ${pkgs.hyprland}/bin/hyprctl keyword monitor "''${pick},preferred,auto,1" ;;
      esac
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

      if [ "$APPLET" = "notifications" ]; then
        exit 0
      fi

      if [ "$APPLET" = "battery" ]; then
        systemctl --user start powerdevil.service 2>/dev/null || true
        sleep 0.5
      fi

      if pgrep -af "plasmawindowed.*''${PLASMOID}" >/dev/null 2>&1; then
        pkill -f "plasmawindowed.*''${PLASMOID}"
        exit 0
      fi

      ${pkgs.kdePackages.plasma-workspace}/bin/plasmawindowed "$PLASMOID" &
    '';
  };

  xdg.configFile."hypr/scripts/media-feedback.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      ${pkgs.wireplumber}/bin/pw-play "${volumeSound}" >/dev/null 2>&1 &
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
              if [ -f "$XDG_RUNTIME_DIR/hyprland-show-desktop" ] && [ "''${ws}" != "4" ]; then
                rm -f "$XDG_RUNTIME_DIR/hyprland-show-desktop"
              fi
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
        ${pkgs.wireplumber}/bin/pw-play "''${1}" >/dev/null 2>&1 &
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
