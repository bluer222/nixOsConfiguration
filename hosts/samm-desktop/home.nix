{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/home/hyprland/default.nix
  ];

  home = {
    username = "samm";
    homeDirectory = "/home/samm";
    stateVersion = "25.11";

    packages = with pkgs; [
      brave
    ];
  };
  /*
  xdg.desktopEntries = {
    "brave-browser" = {
      name = "Brave Web Browser";
      genericName = "Web Browser";
      exec = "brave %U";
      terminal = false;
      categories = [ "Network" "WebBrowser" ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/chromium"
        "application/pdf"
        "application/x-x509-ca-cert"
      ];
      icon = "brave-browser";
      startupNotify = true;
      actions = {
        new-window = {
          name = "New Window";
          exec = "brave";
        };
        new-private-window = {
          name = "New Incognito Window";
          exec = "brave --incognito";
        };
      };
    };
    "com.brave.Browser" = {
      name = "Brave Web Browser";
      genericName = "Web Browser";
      exec = "brave %U";
      terminal = false;
      categories = [ "Network" "WebBrowser" ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/chromium"
        "application/pdf"
        "application/x-x509-ca-cert"
      ];
      icon = "brave-browser";
      startupNotify = true;
    };
  };*/

  home.file.".local/bin/signal-desktop" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      exec ${pkgs.signal-desktop}/bin/signal-desktop "$@"
    '';
  };

  home.activation.migrateKeyringStorage = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for safe in \
      "$HOME/.config/Signal/safeStorage.json" \
      "$HOME/.config/BraveSoftware/Brave-Browser/Local State" \
      "$HOME/.config/chromium/Local State"
    do
      if [ ! -f "$safe" ]; then
        continue
      fi
      if grep -qiE 'basic_text|prev_init_success.:false|gnome-libsecret' "$safe" 2>/dev/null; then
        $DRY_RUN_CMD mv "$safe" "$safe.hm-backup-keyring-$(date +%s)"
      fi
    done
    if [ -f "$HOME/.config/Signal/config.json" ] && \
       grep -q '"safeStorageBackend"[[:space:]]*:[[:space:]]*"basic_text"' "$HOME/.config/Signal/config.json" 2>/dev/null; then
      $DRY_RUN_CMD mv "$HOME/.config/Signal/config.json" "$HOME/.config/Signal/config.json.hm-backup-keyring-$(date +%s)"
    fi
  '';

  /*
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "text/html" = [ "brave-browser.desktop" "com.brave.Browser.desktop" ];
      "inode/directory" = [ "org.kde.dolphin.desktop" ];
      "x-scheme-handler/file" = [ "org.kde.dolphin.desktop" ];
    };
  };*/

  programs.home-manager.enable = true;
}
