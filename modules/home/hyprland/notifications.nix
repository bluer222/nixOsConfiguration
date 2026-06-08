{ config, pkgs, ... }:

{
  services.mako = {
    enable = true;
    settings = {
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#94e2d5";
      border-size = 2;
      border-radius = 8;
      padding = "8";
      margin = "10";
      font = "Inter 12";
      default-timeout = 5000;
    };
  };
}
