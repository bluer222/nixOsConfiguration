{ config, pkgs, ... }:

let
  launcher = pkgs.writeShellApplication {
    name = "nvidia-gpu-reset";
    runtimeInputs = [ pkgs.systemd pkgs.libnotify ];
    text = ''
      if systemctl start nvidia-gpu-reset.service; then
        notify-send "NVIDIA GPU reset" "GPU reset complete; nvidia-powerd and LACT restarted."
      else
        notify-send --urgency=critical "NVIDIA GPU reset failed" \
          "Check journalctl -u nvidia-gpu-reset.service for details."
        exit 1
      fi
    '';
  };
in
{
  systemd.services.nvidia-gpu-reset = {
    description = "Stop NVIDIA GPU clients and reset the GPU";
    enableStrictShellChecks = true;
    path = [ pkgs.psmisc config.hardware.nvidia.package.bin ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "60s";
    };
    script = ''
      set -euo pipefail
      shopt -s nullglob

      devices=()
      for device in /dev/nvidia* /dev/nvidia-caps/*; do
        if [[ -c "$device" ]]; then
          devices+=("$device")
        fi
      done
      # DRM clients may hold only a render/card node, not /dev/nvidia*.
      for device in /sys/class/drm/*; do
        if [[ -c "/dev/dri/''${device##*/}" && -r "$device/device/vendor" ]] \
          && [[ $(cat "$device/device/vendor") == 0x10de ]]; then
          devices+=("/dev/dri/''${device##*/}")
        fi
      done
      if (( ''${#devices[@]} == 0 )); then
        echo "No NVIDIA GPU device files found." >&2
        exit 1
      fi

      systemctl stop lactd.service
      systemctl stop nvidia-powerd.service

      # Give clients time to exit before killing any remaining users.
      fuser -k -TERM -- "''${devices[@]}" || true
      for (( attempt=0; attempt<50; attempt++ )); do
        if ! fuser -s -- "''${devices[@]}"; then
          break
        fi
        sleep 0.1
      done
      if fuser -s -- "''${devices[@]}"; then
        fuser -k -KILL -- "''${devices[@]}" || true
        sleep 1
      fi

      nvidia-smi --gpu-reset
    '';
    # ExecStopPost also runs when the reset fails or times out.
    postStop = ''
      status=0
      systemctl restart nvidia-powerd.service || status=$?
      systemctl restart lactd.service || status=$?
      exit "$status"
    '';
  };

  environment.systemPackages = [
    launcher
    (pkgs.makeDesktopItem {
      name = "nvidia-gpu-reset";
      desktopName = "Reset NVIDIA GPU";
      comment = "Close NVIDIA GPU applications, reset the GPU, and restart power management";
      exec = "${launcher}/bin/nvidia-gpu-reset";
      icon = "view-refresh";
      categories = [ "System" ];
      keywords = [ "NVIDIA" "GPU" "Reset" "LACT" ];
      terminal = false;
    })
  ];
}
