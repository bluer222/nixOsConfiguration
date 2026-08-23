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

  # No keyring of any kind: no gnome-keyring, no KWallet. Brave runs in
  # basic mode (local obfuscation only) — accepted tradeoff under autologin
  # where the LUKS volume is the security boundary.
  services.gnome.gnome-keyring.enable = lib.mkForce false;
}
