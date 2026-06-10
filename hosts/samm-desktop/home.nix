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
      # Add user-specific packages here
    ];

    sessionVariables = {
      QT_QPA_PLATFORM = "wayland;xcb";
      GDK_BACKEND = "wayland,x11";
      BROWSER = "brave-browser";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      XDG_MENU_PREFIX = "plasma-";
    };
  };

  # Reset stale kwallet/broken portal encryption so apps use gnome-keyring.
  home.activation.migrateKeyringStorage = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for safe in \
      "$HOME/.config/Signal/safeStorage.json" \
      "$HOME/.config/BraveSoftware/Brave-Browser/Local State" \
      "$HOME/.config/chromium/Local State"
    do
      if [ ! -f "$safe" ]; then
        continue
      fi
      if grep -qiE 'kwallet|basic_text|prev_init_success.:false' "$safe" 2>/dev/null; then
        $DRY_RUN_CMD mv "$safe" "$safe.hm-backup-keyring-$(date +%s)"
      fi
    done
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "brave-browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" ];
      "text/html" = [ "brave-browser.desktop" ];
      "inode/directory" = [ "org.kde.dolphin.desktop" ];
      "x-scheme-handler/file" = [ "org.kde.dolphin.desktop" ];
    };
  };

  # xdg-open still calls kfmclient on KDE-ish systems; forward to kioclient/dolphin.
  home.file.".local/bin/kfmclient" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      case "$1" in
        exec)
          shift
          exec ${pkgs.kdePackages.dolphin}/bin/dolphin "$@"
          ;;
        openURL|openProfile)
          shift
          exec ${pkgs.kdePackages.kde-cli-tools}/bin/kde-open "$@"
          ;;
        *)
          exec ${pkgs.kdePackages.kde-cli-tools}/bin/kioclient "$@"
          ;;
      esac
    '';
  };

  programs.home-manager.enable = true;
}
