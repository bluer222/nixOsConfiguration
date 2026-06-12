{ config, pkgs, ... }:

let
  xfceSessionPackage = pkgs.xfce4-session.overrideAttrs (old: {
    passthru = (old.passthru or { }) // { providedSessions = [ "xfce" ]; };
  });
in {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Must be set before Hyprland starts (hyprland.lua env is too late).
  # intel-igpu and nvidia-dgpu are stable symlinks created by udev rules in gpu.nix.
  environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu";

  services.displayManager = {
    defaultSession = "hyprland";
    sessionPackages = with pkgs; [
      hyprland
      xfceSessionPackage
    ];
  };
}
