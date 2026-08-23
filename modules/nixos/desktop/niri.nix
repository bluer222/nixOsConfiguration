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
  ];

  # Prefer KWallet over gnome-keyring (nixpkgs niri enables keyring by default).
  services.gnome.gnome-keyring.enable = lib.mkForce false;
}
