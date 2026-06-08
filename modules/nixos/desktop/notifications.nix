{ config, pkgs, ... }:
{
  services.mako = {
    enable = true;
    # Basic appearance matching Catppuccin Mocha theme
    backgroundColor = "#1e1e2e"; # base
    textColor = "#cdd6f4";       # text
    borderColor = "#94e2d5";     # teal accent
    borderSize = 2;
    borderRadius = 8;
    padding = "8";
    margin = "10";
    font = "Inter 12";
    defaultTimeout = 5000; # ms
  };
}
