{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    swaybg
    kdialog
  ];

  xdg.configFile."hypr/scripts/change_wallpaper.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Helper script to change wallpaper per workspace across all monitors
      
      WORKSPACE=$1
      
      # Define placeholder wallpaper files for each workspace
      WP1="/tmp/wp_workspace_1.png"
      WP2="/tmp/wp_workspace_2.png"
      WP3="/tmp/wp_workspace_3.png"

      # Create placeholders if they don't exist
      if [ ! -f "$WP1" ]; then
        # Just create simple colored images using imagemagick if available, or just touch the file
        echo "Creating placeholder wallpapers in /tmp"
        touch $WP1 $WP2 $WP3
      fi

      WP=""
      case $WORKSPACE in
        1) WP="$WP1" ;;
        2) WP="$WP2" ;;
        3) WP="$WP3" ;;
        *) WP="$WP1" ;;
      esac

      # If the file exists and has size, use swaybg
      if [ -s "$WP" ]; then
        # Kill old swaybg instances
        killall swaybg
        # Launch new one
        swaybg -i "$WP" -m fill &
      fi
    '';
  };

  xdg.configFile."hypr/scripts/wallpaper_init.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Run the change script for workspace 1 on startup
      ~/.config/hypr/scripts/change_wallpaper.sh 1
    '';
  };

  xdg.configFile."hypr/scripts/toggle_trackpad.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Toggle the trackpad state dynamically

      # Find trackpad name from hyprctl devices
      TRACKPAD=$(hyprctl devices -j | jq -r '.mice[] | select(.name | contains("touchpad") or contains("trackpad")) | .name' | head -n 1)

      if [ -z "$TRACKPAD" ]; then
        echo "No trackpad found"
        exit 1
      fi

      # Get current state
      # hyprctl getoption does not return device specific options easily, 
      # but we can track state in a file
      STATE_FILE="/tmp/hypr_trackpad_state"

      if [ ! -f "$STATE_FILE" ]; then
        echo "1" > "$STATE_FILE"
      fi

      STATE=$(cat "$STATE_FILE")

      if [ "$STATE" -eq 1 ]; then
        hyprctl keyword "device:$TRACKPAD:enabled" false
        echo "0" > "$STATE_FILE"
        echo "Trackpad Disabled"
      else
        hyprctl keyword "device:$TRACKPAD:enabled" true
        echo "1" > "$STATE_FILE"
        echo "Trackpad Enabled"
      fi
    '';
  };

  xdg.configFile."hypr/scripts/volume.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Handle volume and play feedback sound
      
      ACTION=$1
      
      case $ACTION in
        up)
          wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
          ;;
        down)
          wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
          ;;
        mute)
          wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
          ;;
      esac
      
      # Play Oxygen sound (don't block)
      paplay /run/current-system/sw/share/sounds/oxygen/stereo/audio-volume-change.ogg || paplay ~/.nix-profile/share/sounds/oxygen/stereo/audio-volume-change.ogg || true &
    '';
  };

  xdg.configFile."hypr/scripts/qt-popup.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      APPLET=''${1:-}
      case "$APPLET" in
        volume)
          PLASMOID="org.kde.plasma.volume"
          ;;
        bluetooth)
          PLASMOID="org.kde.plasma.bluetooth"
          ;;
        *)
          exit 2
          ;;
      esac

      if pgrep -af "plasmawindowed $PLASMOID" >/dev/null; then
        pkill -f "plasmawindowed $PLASMOID"
        exit 0
      fi

      hyprctl dispatch exec "[float; size 380 460; move 100%-392 32; opacity 0.97 0.97] plasmawindowed $PLASMOID"
    '';
  };

  xdg.configFile."hypr/scripts/screenshot-region.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      mkdir -p "$HOME/Pictures/Screenshots"
      OUT="$HOME/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png"
      GEOMETRY=$(slurp -d)

      grim -g "$GEOMETRY" "$OUT"
      swappy -f "$OUT"
    '';
  };
}
