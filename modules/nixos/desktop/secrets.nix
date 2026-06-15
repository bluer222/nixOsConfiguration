{ config, pkgs, lib, ... }:

{
  # KWallet unlocks at greetd login via PAM (same as SDDM + Plasma).
  security.pam.services.login = {
    kwallet = {
      enable = true;
      forceRun = true;
    };
  };

  security.pam.services.greetd = {
    kwallet = {
      enable = true;
      forceRun = true;
    };
  };
}
