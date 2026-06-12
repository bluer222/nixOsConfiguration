{ pkgs, config, ... }:

{
  imports = [
    ./hyprland/settings.nix
    ./hyprland/binds.nix
    ./hyprland/extra-lua.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    plugins = [
      pkgs.hyprlandPlugins.hypr-dynamic-cursors
      pkgs.hyprlandPlugins.hypr-darkwindow
    ];

    configType = "lua";
    extraConfig = "";
  };
}
