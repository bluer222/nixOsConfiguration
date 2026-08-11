{ config, lib, ... }:

let
  cliphistDb = "${config.xdg.dataHome}/cliphist/db";
in {
  xdg.configFile."cliphist/config".text = ''
    db-path ${cliphistDb}
    max-items 500
    max-dedupe-search 10
  '';

  services.cliphist = {
    enable = true;
    allowImages = true;
  };
}
