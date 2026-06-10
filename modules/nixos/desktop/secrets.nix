{ config, pkgs, lib, ... }:

{
  # KWallet unlocks at greetd login via PAM (same as SDDM + Plasma).
  security.pam.services.login = {
    enableGnomeKeyring = lib.mkForce false;
    kwallet = {
      enable = true;
      forceRun = true;
    };
  };

  security.pam.services.greetd = {
    enableGnomeKeyring = lib.mkForce false;
    kwallet = {
      enable = true;
      forceRun = true;
    };
  };
}
