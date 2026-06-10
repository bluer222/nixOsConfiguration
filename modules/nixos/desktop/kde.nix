{ config, pkgs, lib, ... }:

{
  # KDE libraries and apps only — no Plasma session or login manager.
  programs.kdeconnect.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    OBS_USE_EGL = "1";
    CHROMIUM_FLAGS =
      "--enable-features=UsePortal,WaylandWpFilePicker --password-store=gnome-libsecret";
  };

  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.login.kwallet.enable = lib.mkForce false;
  security.pam.services.greetd.kwallet.enable = lib.mkForce false;
}
