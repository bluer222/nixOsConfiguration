{ config, pkgs, lib, ... }:

let
  sessions = config.services.displayManager.sessionData.desktops;
  tuigreetCmd =
    "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session "
    + "--user-menu --user-menu-min-uid 1000 "
    + "--xsessions ${sessions}/share/xsessions "
    + "--sessions ${sessions}/share/wayland-sessions";
in {
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      default_session = {
        command = tuigreetCmd;
        user = "greeter";
      };
    };
  };
}
