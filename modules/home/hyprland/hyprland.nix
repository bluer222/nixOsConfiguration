{ pkgs, config, ... }:

{
  imports = [
    ./hyprland/settings.nix
    ./hyprland/binds.nix
    ./hyprland/extra-lua.nix
    ./hyprland/sounds.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    package = pkgs.hyprland;

    plugins = [
      pkgs.hyprlandPlugins.hypr-dynamic-cursors
      pkgs.hyprlandPlugins.hypr-darkwindow
    ];

    configType = "lua";
    extraConfig = "";
  };
}
