{ config, pkgs, ... }:

{
  services.mako = {
    enable = true;
    backgroundColor = "#1e1e2e";
    textColor = "#cdd6f4";
    borderColor = "#94e2d5";
    borderSize = 2;
    borderRadius = 8;
    padding = "8";
    margin = "10";
    font = "Inter 12";
    defaultTimeout = 5000;
  };
}
