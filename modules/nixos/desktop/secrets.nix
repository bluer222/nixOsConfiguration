{ config, pkgs, lib, ... }:

{
  # pass-backed org.freedesktop.secrets — dbus-activated, no GNOME/KWallet daemons.
  services.passSecretService.enable = true;

  programs.gnupg = {
    agent.enable = true;
    dirmngr.enable = true;
  };

  security.pam.services.login = {
    enableGnomeKeyring = lib.mkForce false;
    kwallet.enable = lib.mkForce false;
    gnupg.enable = true;
  };

  security.pam.services.greetd = {
    enableGnomeKeyring = lib.mkForce false;
    kwallet.enable = lib.mkForce false;
    gnupg.enable = true;
  };
}
