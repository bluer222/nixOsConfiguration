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
      default-timeout = 8000;
      ignore-timeout = false;
      max-visible = 5;
      layer = "overlay";

      # Left click: default action. Middle click: copy body to clipboard.
      "on-button-left" = "invoke-default-action";
      "on-button-middle" = "exec makoctl history | jq -r '.data[] | select(.id.data == '\$id') | .body.data' | wl-copy";
    };
  };
}
