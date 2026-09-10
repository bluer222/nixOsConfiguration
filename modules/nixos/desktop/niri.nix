{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
    # Keep Nautilus/GNOME file-chooser out; KDE portal is preferred.
    useNautilus = false;
  };

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "samm";
      };
      default_session = {
        command = "${pkgs.greetd}/bin/agreety --cmd ${lib.escapeShellArg "${pkgs.niri}/bin/niri-session"}";
      };
    };
  };

  # Don't clobber PATH imported by niri-session into the user manager.
  systemd.user.services.niri.enableDefaultPath = false;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    niri-helper
    seahorse
    libsecret
  ];

  # FreeDesktop Secret Service via GNOME Keyring daemon.
  # Under autologin + LUKS full-disk encryption, a blank password on the login keyring
  # allows it to unlock automatically without password prompts.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
}
