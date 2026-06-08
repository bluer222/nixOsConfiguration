{ config, pkgs, lib, ... }:

let
  cfg = config.services.portmaster;
  settingsFormat = pkgs.formats.json { };
  inherit (lib) escapeShellArg escapeShellArgs mapAttrsToList mkIf mkForce;
  inherit (lib.strings) sanitizeDerivationName;

  # Helper to generate robust regex fingerprints matching any executable in a package store path prefix
  pkgRegex = pkg: [
    {
      type = "path";
      operation = "regex";
      value = "^${lib.escapeRegex (toString pkg)}/.*";
    }
  ];

  allowInternet = {
    "filter/blockInternet" = false;
    "filter/blockP2P" = false;
  };
  allowLAN = {
    "filter/blockLAN" = false;
    "filter/blockP2P" = false;
  };
  allowInbound = {
    "filter/blockInbound" = false;
    "filter/blockP2P" = false;
  };
  allowLANInbound = allowLAN // allowInbound;
  allowInternetLAN = allowInternet // allowLAN;
  allowInternetInbound = allowInternet // allowInbound;
  allowInternetLANInbound = allowInternet // allowLANInbound;

  managedProfileExports = mapAttrsToList (
    logicalName: profileCfg:
    settingsFormat.generate "portmaster-profile-${sanitizeDerivationName logicalName}.json" {
      type = "profile";
      source = "local";
      inherit (profileCfg) name;
      fingerprints = profileCfg.identity.fingerprints;
      config = profileCfg.settings;
    }
  ) cfg.managedProfiles;
in
{
  services.portmaster = {
    enable = true;
    settings = {
      devmode = true; # UI at 127.0.0.1:817
      "filter/blockInternet" = false;  # Allow by default; profiles will restrict specific apps
      "filter/blockLAN" = false;       # Allow LAN by default
      "filter/blockInbound" = true;   # Block inbound by default
      "filter/blockP2P" = false;        # Block P2P by default for security
    };

    managedProfiles = {
      # --- System Core ---
      nix = {
        name = "Nix";
        identity.fingerprints = pkgRegex pkgs.nix;
        settings = allowInternet;
      };
      
      systemd = {
        name = "systemd";
        identity.fingerprints = pkgRegex pkgs.systemd;
        settings = allowInternet;
      };

      # --- System Services ---
      geoclue = {
        name = "Geoclue";
        identity.fingerprints = pkgRegex pkgs.geoclue2;
        settings = allowInternet;
      };

      nsncd = {
        name = "nsncd";
        identity.fingerprints = pkgRegex pkgs.nsncd;
        settings = allowInternet;
      };

      fwupd = {
        name = "fwupd";
        identity.fingerprints = pkgRegex pkgs.fwupd;
        settings = allowInternet;
      };

      flatpak = {
        name = "Flatpak";
        identity.fingerprints = pkgRegex pkgs.flatpak;
        settings = allowInternet;
      };

      cups = {
        name = "CUPS";
        identity.fingerprints = pkgRegex pkgs.cups;
        settings = allowInternetLANInbound;
      };

      ssh = {
        name = "SSH";
        identity.fingerprints = pkgRegex pkgs.openssh;
        settings = allowInternet;
      };

      # --- Essential Interactive Tools ---
      gemini-cli = {
        name = "Gemini CLI";
        identity.fingerprints = pkgRegex pkgs.gemini-cli;
        settings = allowInternet;
      };

      git = {
        name = "Git";
        identity.fingerprints = pkgRegex pkgs.git;
        settings = allowInternet;
      };

      curl = {
        name = "curl";
        identity.fingerprints = pkgRegex pkgs.curl;
        settings = allowInternet;
      };

      wget = {
        name = "wget";
        identity.fingerprints = pkgRegex pkgs.wget;
        settings = allowInternet;
      };

      # --- Browsers & Communication ---
      brave = {
        name = "Brave Browser";
        identity.fingerprints = pkgRegex pkgs.brave;
        settings = allowInternet;
      };

      zoom = {
        name = "Zoom";
        identity.fingerprints = pkgRegex pkgs.zoom-us;
        settings = allowInternet;
      };

      postman = {
        name = "Postman";
        identity.fingerprints = pkgRegex pkgs.postman;
        settings = allowInternet;
      };

      # --- Gaming & Streaming ---
      steam = {
        name = "Steam";
        identity.fingerprints = pkgRegex pkgs.steam;
        settings = allowInternetLANInbound;
      };

      lutris = {
        name = "Lutris";
        identity.fingerprints = pkgRegex pkgs.lutris;
        settings = allowInternet;
      };

      godot = {
        name = "Godot Engine";
        identity.fingerprints = pkgRegex pkgs.godot_4;
        settings = allowInternet;
      };

      winetricks = {
        name = "Winetricks";
        identity.fingerprints = pkgRegex pkgs.winetricks;
        settings = allowInternet;
      };

      obs-studio = {
        name = "OBS Studio";
        identity.fingerprints = pkgRegex pkgs.obs-studio;
        settings = allowInternetLANInbound;
      };

      vlc = {
        name = "VLC Media Player";
        identity.fingerprints = pkgRegex pkgs.vlc;
        settings = allowInternet;
      };

      wivrn = {
        name = "WiVRn VR Streamer";
        identity.fingerprints = pkgRegex pkgs.wivrn;
        settings = allowInternetLANInbound;
      };

      # --- Discovery & Synchronization ---
      kdeconnect = {
        name = "KDE Connect";
        identity.fingerprints = pkgRegex pkgs.kdePackages.kdeconnect-kde;
        settings = allowLANInbound;
      };

      avahi = {
        name = "Avahi Daemon";
        identity.fingerprints = pkgRegex pkgs.avahi;
        settings = allowLANInbound;
      };

      # --- Specialized Tools ---
      proton-vpn = {
        name = "Proton VPN";
        identity.fingerprints = pkgRegex pkgs.proton-vpn;
        settings = allowInternet;
      };

      nicotine-plus = {
        name = "Nicotine+";
        identity.fingerprints = pkgRegex pkgs.nicotine-plus;
        settings = allowInternetInbound;
      };

      immich-go = {
        name = "Immich-go";
        identity.fingerprints = pkgRegex pkgs.immich-go;
        settings = allowInternet;
      };

      kiwix = {
        name = "Kiwix";
        identity.fingerprints = pkgRegex pkgs.kiwix;
        settings = allowInternet;
      };

      kubectl = {
        name = "kubectl";
        identity.fingerprints = pkgRegex pkgs.kubectl;
        settings = allowInternet;
      };

      # --- Development Tools ---
      vscode = {
        name = "VS Code";
        identity.fingerprints = pkgRegex pkgs.vscode;
        settings = allowInternet;
      };

      android-studio = {
        name = "Android Studio";
        identity.fingerprints = pkgRegex pkgs.android-studio;
        settings = allowInternet;
      };

      arduino-ide = {
        name = "Arduino IDE";
        identity.fingerprints = pkgRegex pkgs.arduino-ide;
        settings = allowInternet;
      };

      neovim = {
        name = "Neovim";
        identity.fingerprints = pkgRegex pkgs.neovim;
        settings = allowInternet;
      };

      antigravity = {
        name = "Antigravity AI Agent";
        identity.fingerprints = pkgRegex pkgs.antigravity;
        settings = allowInternet;
      };

      docker = {
        name = "Docker";
        identity.fingerprints = pkgRegex pkgs.docker;
        settings = allowInternetLAN;
      };

      qgroundcontrol = {
        name = "QGroundControl";
        identity.fingerprints = pkgRegex pkgs.qgroundcontrol;
        settings = allowInternetLANInbound;
      };

      scrcpy = {
        name = "scrcpy";
        identity.fingerprints = pkgRegex pkgs.scrcpy;
        settings = allowInternetLANInbound;
      };

      servo = {
        name = "Servo Browser";
        identity.fingerprints = pkgRegex pkgs.servo;
        settings = allowInternet;
      };

      yt-dlp = {
        name = "yt-dlp";
        identity.fingerprints = pkgRegex pkgs.yt-dlp;
        settings = allowInternet;
      };

      mediawriter = {
        name = "Fedora Media Writer";
        identity.fingerprints = pkgRegex pkgs.mediawriter;
        settings = allowInternet;
      };

      onlyoffice = {
        name = "ONLYOFFICE";
        identity.fingerprints = pkgRegex pkgs.onlyoffice-desktopeditors;
        settings = allowInternet;
      };

      ocs-url = {
        name = "ocs-url";
        identity.fingerprints = pkgRegex pkgs.ocs-url;
        settings = allowInternet;
      };

      ckan = {
        name = "CKAN Mod Manager";
        identity.fingerprints = pkgRegex pkgs.ckan;
        settings = allowInternet;
      };

      digikam = {
        name = "DigiKam";
        identity.fingerprints = pkgRegex pkgs.digikam;
        settings = allowInternet;
      };

      cura = {
        name = "Cura Slicer";
        identity.fingerprints = pkgRegex pkgs.cura-appimage;
        settings = allowInternetLANInbound;
      };

      # --- Security Research ---
      tor-browser = {
        name = "Tor Browser";
        identity.fingerprints = pkgRegex pkgs.tor-browser;
        settings = allowInternet;
      };

      nmap = {
        name = "nmap";
        identity.fingerprints = pkgRegex pkgs.nmap;
        settings = allowInternetLAN;
      };

      metasploit = {
        name = "Metasploit";
        identity.fingerprints = pkgRegex pkgs.metasploit;
        settings = allowInternetLAN;
      };

      burpsuite = {
        name = "Burp Suite";
        identity.fingerprints = pkgRegex pkgs.burpsuite;
        settings = allowInternetLANInbound;
      };

      rustscan = {
        name = "RustScan";
        identity.fingerprints = pkgRegex pkgs.rustscan;
        settings = allowInternetLAN;
      };

      # --- Desktop & Services ---
      kmail = {
        name = "KMail";
        identity.fingerprints = pkgRegex pkgs.kdePackages.kmail;
        settings = allowInternet;
      };

      automatic-timezoned = {
        name = "Automatic Timezoned";
        identity.fingerprints = pkgRegex pkgs.automatic-timezoned;
        settings = allowInternet;
      };

      waydroid = {
        name = "Waydroid";
        identity.fingerprints = pkgRegex pkgs.waydroid-nftables;
        settings = allowInternetLANInbound;
      };
    };
  };

  systemd.services.portmaster-managed-profiles = mkIf (cfg.enable && cfg.managedProfiles != { }) {
    after = [ "portmaster.service" ];
    wants = [ "portmaster.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 10;
      LoadCredential = "managed-profiles-api-key:${pkgs.writeText "portmaster-api-key" ""}";
    };
    
    script = mkForce ''
      set -euo pipefail

      curl_config="$(${pkgs.coreutils}/bin/mktemp --tmpdir portmaster-managed-profiles-curl.XXXXXX)"
      trap '${pkgs.coreutils}/bin/rm -f "$curl_config"' EXIT
      ${pkgs.coreutils}/bin/chmod 0600 "$curl_config"
      printf '%s' 'header = "Authorization: Bearer ' > "$curl_config"
      ${pkgs.coreutils}/bin/tr -d '\r\n' < "$CREDENTIALS_DIRECTORY/managed-profiles-api-key" >> "$curl_config"
      printf '%s\n' '"' >> "$curl_config"

      # Give portmaster daemon time to fully start before attempting API calls
      ${pkgs.coreutils}/bin/sleep 2

      ready=0
      for _ in $(${pkgs.coreutils}/bin/seq 1 180); do
        if ${pkgs.curl}/bin/curl --silent --show-error --fail --noproxy '*' --max-time 2 http://127.0.0.1:817/api/v1/ping > /dev/null 2>&1; then
          ready=1
          break
        fi
        ${pkgs.coreutils}/bin/sleep 1
      done

      if [ "$ready" -ne 1 ]; then
        printf >&2 '%s\n' "Portmaster API at http://127.0.0.1:817/api/v1/ping did not become ready in time"
        exit 1
      fi

      for profile in ${escapeShellArgs managedProfileExports}; do
        ${pkgs.jq}/bin/jq -e '
          .type == "profile"
          and (.source == "local")
          and (.name | type == "string" and length > 0)
          and (.config | type == "object")
          and (.fingerprints | type == "array")
          and (.fingerprints | length > 0)
          and all(
            .fingerprints[];
            (.type == "path" or .type == "cmdline")
            and (.operation == "equals" or .operation == "regex")
            and (.value | type == "string" and length > 0)
          )
        ' "$profile" > /dev/null

        response="$(${pkgs.curl}/bin/curl \
          --config "$curl_config" \
          --silent \
          --show-error \
          --fail \
          --noproxy '*' \
          --max-time 30 \
          --header "Content-Type: application/json" \
          --data-binary "$(${pkgs.jq}/bin/jq -n --rawfile rawExport "$profile" '{
            rawExport: $rawExport,
            rawMime: "application/json",
            validateOnly: false,
            reset: false,
            allowUnknown: false,
            allowReplaceProfiles: true
          }')" \
          ${escapeShellArg "http://127.0.0.1:817/api/v1/sync/profile/import"})"

        printf '%s' "$response" | ${pkgs.jq}/bin/jq -e '
          (.restartRequired | type == "boolean")
          and (.replacesExisting | type == "boolean")
        ' > /dev/null
      done
    '';
  };
}
