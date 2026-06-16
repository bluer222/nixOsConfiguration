{ pkgs, ... }:

{
  # KWallet packages — kwallet provides ksecretd (the KF6 Secret Service daemon),
  # kwallet-pam provides the PAM module that unlocks the wallet at login.
  environment.systemPackages = with pkgs; [
    kdePackages.kwallet
    kdePackages.kwallet-pam
  ];

  # Unlock the default kdewallet on login via PAM.
  # We target the `login` service (not `greetd`) because tuigreet is a TTY-style
  # greeter that goes through the login PAM stack. The greetd PAM service is
  # currently broken for kwallet (nixpkgs#357201).
  # `forceRun` is required when starting a Wayland session from a TTY.
  security.pam.services.login.kwallet = {
    enable = true;
    forceRun = true;
  };
}
