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
  # card1 = Intel iGPU, card0 = NVIDIA dGPU on this Prime offload laptop.
  environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";

  services.displayManager = {
    defaultSession = "hyprland";
    sessionPackages = with pkgs; [
      hyprland
      xfceSessionPackage
    ];
  };
}
