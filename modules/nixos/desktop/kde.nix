{ config, pkgs, lib, ... }:

{
  # KDE libraries and apps only — no Plasma session or login manager.
  programs.kdeconnect.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    OBS_USE_EGL = "1";
    CHROMIUM_FLAGS =
      "--enable-features=UsePortal --disable-features=WaylandWpFilePicker,DbusSecretPortal --ozone-platform=wayland";
  };

}
