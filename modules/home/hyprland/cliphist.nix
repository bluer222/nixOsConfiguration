{ config, lib, ... }:

let
  cliphistDb = "${config.xdg.dataHome}/cliphist/db";
in {
  xdg.configFile."cliphist/config".text = ''
    db-path ${cliphistDb}
    max-items 500
    max-dedupe-search 10
  '';

  home.activation.migrateCliphistDb = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    oldDb="$HOME/.cache/cliphist/db"
    newDb="${cliphistDb}"
    if [ -f "$oldDb" ] && [ ! -f "$newDb" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$newDb")"
      $DRY_RUN_CMD cp "$oldDb" "$newDb"
    fi
  '';

  services.cliphist = {
    enable = true;
    allowImages = true;
  };
}
