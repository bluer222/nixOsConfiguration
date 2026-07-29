{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop";
        user = "samm";
      };
      default_session = {
        command = "${pkgs.greetd}/bin/agreety --cmd ${lib.escapeShellArg "${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop"}";
      };
    };
  };
}
