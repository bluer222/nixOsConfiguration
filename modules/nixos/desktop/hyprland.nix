{ config, pkgs, lib, ... }:

let
  xfceSessionPackage = pkgs.xfce4-session.overrideAttrs (old: {
    passthru = (old.passthru or { }) // { providedSessions = [ "xfce" ]; };
  });

  hyprPkg = config.programs.hyprland.package;

  # Prefer package bin over /run/wrappers/bin. start-hyprland execvp("Hyprland")
  # otherwise hits the fcaps wrapper and dies with:
  #   failed to inherit capabilities: Operation not permitted
  hyprPathUnit =
    "${hyprPkg}/bin:/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";

  # Wait until i915 owns the panel and plymouth has released the DRM master.
  waitDrm = pkgs.writeShellScript "hyprland-wait-drm" ''
    set -euo pipefail
    if command -v plymouth >/dev/null 2>&1; then
      plymouth quit --retain-splash 2>/dev/null || true
    fi
    for _ in $(seq 1 100); do
      if [ -e /dev/dri/intel-igpu ]; then
        card=$(basename "$(readlink -f /dev/dri/intel-igpu)")
        for status_file in /sys/class/drm/"$card"-eDP-*/status; do
          [ -e "$status_file" ] || continue
          if [ "$(cat "$status_file" 2>/dev/null || true)" = "connected" ]; then
            exit 0
          fi
        done
      fi
      sleep 0.1
    done
    exit 0
  '';
in {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # Must be set before Hyprland starts (hyprland.lua env is too late).
  # ONLY the iGPU: the panel is on eDP-1/card1. nvidia-dgpu has no CRTCs here
  # (PRIME offload); listing it in AQ_DRM_DEVICES can hard-hang the compositor.
  environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/intel-igpu";
  environment.sessionVariables.LIBSEAT_BACKEND = "logind";

  # PATH must put package bin before /run/wrappers/bin (see above).
  # Do NOT run `systemctl --user set-environment` from ExecStartPre — it stops
  # this unit mid-start (instant stop-sigterm / SIGKILL cycle).
  systemd.user.services."wayland-wm@hyprland.desktop" = {
    serviceConfig = {
      ExecStartPre = [ "${waitDrm}" ];
      Environment = [ "PATH=${hyprPathUnit}" ];
      TimeoutStartSec = "60";
      TimeoutStopSec = "10";
      FinalKillSignal = "SIGKILL";
      SendSIGKILL = true;
    };
  };

  systemd.user.services."wayland-wm-env@hyprland.desktop" = {
    serviceConfig = {
      Environment = [ "PATH=${hyprPathUnit}" ];
    };
  };

  services.displayManager = {
    defaultSession = "hyprland-uwsm";
    sessionPackages = [
      hyprPkg
      xfceSessionPackage
    ];
  };
}
