{ config, pkgs, lib, ... }:

let
  pkgRegex = pkg: [
    {
      type = "path";
      operation = "regex";
      value = "^${lib.escapeRegex (toString pkg)}/.*";
    }
  ];

  mkPathRegex = value: {
    type = "path";
    operation = "regex";
    value = value;
  };

  mkPathEquals = path: {
    type = "path";
    operation = "equals";
    value = path;
  };

  # Per-profile rule constructor.
  # Always set all filter flags explicitly so profile behavior does not depend on
  # global defaults.
  # Profile imports require nested config keys (filter.blockInbound), not the flat
  # slash keys used by global runtime config.json (filter/blockInbound).
  mkRule = {
    internet ? false,
    lan ? false,
    inbound ? false,
    p2p ? false,
  }: {
    filter = {
      blockInternet = !internet;
      blockLAN = !lan;
      blockInbound = !inbound;
      blockP2P = !p2p;
    };
  };

  # Baseline for most apps: outbound internet only.
  allowInternet = mkRule { internet = true; };
  allowLAN = mkRule { lan = true; };
  allowInbound = mkRule { inbound = true; };
  allowLANInbound = mkRule {
    lan = true;
    inbound = true;
  };
  allowInternetLAN = mkRule {
    internet = true;
    lan = true;
  };
  allowInternetP2P = mkRule {
    internet = true;
    p2p = true;
  };
  # Internet + LAN + P2P, no inbound (browsers, general outbound apps).
  allowInternetLANP2P = mkRule {
    internet = true;
    lan = true;
    p2p = true;
  };
  # Inbound + P2P for peer connectivity (SSH, video calls, torrents).
  allowInternetInbound = mkRule {
    internet = true;
    inbound = true;
    p2p = true;
  };
  allowInternetLANInbound = mkRule {
    internet = true;
    lan = true;
    inbound = true;
  };
in
{
  services.portmaster = {
    enable = true;
    settings = {
      devmode = true; # UI at 127.0.0.1:817
      # Block everything by default; managedProfiles grant explicit per-app access.
      "filter/blockInternet" = true;
      "filter/blockLAN" = true;
      "filter/blockInbound" = true;
      "filter/blockP2P" = true;
    };

    managedProfiles = { #python needs to be added with iternet and p2p
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
        # Service may run from an older store path until restarted; match any geoclue build.
        identity.fingerprints = pkgRegex pkgs.geoclue2 ++ [
          (mkPathRegex "^/nix/store/[^/]+-geoclue-[^/]+/libexec/\\.geoclue-wrapped$")
        ];
        settings = allowInternetP2P;
      };

      nsncd = {
        name = "nsncd";
        identity.fingerprints = pkgRegex pkgs.nsncd;
        settings = allowInternet;
      };

      fwupd = {
        name = "fwupd";
        identity.fingerprints = pkgRegex pkgs.fwupd;
        settings = allowInternetP2P;
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

      cups-browsed = {
        name = "CUPS Browsed";
        identity.fingerprints = pkgRegex pkgs.cups-browsed;
        settings = allowLAN;
      };

      ssh = {
        name = "SSH";
        identity.fingerprints = pkgRegex pkgs.openssh;
        settings = allowInternetLAN;
      };

      # --- Essential Interactive Tools ---
      gemini-cli = {
        name = "Gemini CLI";
        identity.fingerprints = pkgRegex pkgs.gemini-cli;
        settings = allowInternet;
      };

      cursor-agent = {
        name = "Cursor Agent";
        identity.fingerprints = pkgRegex pkgs.cursor-cli ++ [
          (mkPathRegex "^/nix/store/[^/]+-cursor-cli-[^/]+/share/cursor-agent/node$")
        ];
        settings = allowInternetP2P;
      };

      codex = {
        name = "Codex";
        identity.fingerprints = pkgRegex pkgs.codex ++ [
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.vscode/extensions/openai.chatgpt.*")
        ];
        settings = allowInternetP2P;
      };

      git = {
        name = "Git";
        identity.fingerprints = pkgRegex pkgs.git;
        settings = allowInternetP2P;
      };

      curl = {
        name = "curl";
        identity.fingerprints = pkgRegex pkgs.curl;
        settings = allowInternet;
      };

      wget = {
        name = "wget";
        identity.fingerprints = pkgRegex pkgs.wget;
        settings = allowInternetP2P;
      };

      # --- Browsers & Communication ---
      brave = {
        name = "Brave Browser";
        identity.fingerprints = pkgRegex pkgs.brave;
        settings = allowInternetLANP2P;
      };

      zoom = {
        name = "Zoom";
        identity.fingerprints = pkgRegex pkgs.zoom-us;
        settings = allowInternetInbound;
      };

      postman = {
        name = "Postman";
        identity.fingerprints = pkgRegex pkgs.postman;
        settings = allowInternet;
      };

      # --- Gaming & Streaming ---
      steam = {
        name = "Steam";
        identity.fingerprints = pkgRegex pkgs.steam ++ [
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.local/share/Steam/.*")
        ];
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
        settings = allowInternetLAN;
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
        settings = allowInternetP2P;
      };

      android-studio = {
        name = "Android Studio";
        identity.fingerprints = pkgRegex pkgs.android-studio;
        settings = allowInternetP2P;
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

      # --- External / non-Nix paths ---
      twintaillauncher = {
        name = "Twintail Launcher";
        identity.fingerprints = [
          (mkPathEquals "/app/bin/twintaillauncher")
          (mkPathRegex "^/home/samm/.var/app/app.twintaillauncher.ttl/.*")
        ];
        settings = allowInternet;
      };

      android-java = {
        name = "Java for android studio";
        identity.fingerprints = [
          (mkPathRegex "^/home/samm/.jdks/.*")
        ];
        settings = allowInternet;
      };

      webkit-network-process = {
        name = "WebKit Network Process";
        identity.fingerprints = [
          (mkPathEquals "/usr/libexec/webkit2gtk-4.1/WebKitNetworkProcess")
        ];
        settings = allowInternet;
      };
    };
  };

  # Re-import managed profiles periodically so UI deletions get repaired.
  systemd.timers.portmaster-managed-profiles-resync = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "15min";
    };
  };

  systemd.services.portmaster-managed-profiles-resync = {
    description = "Re-sync Portmaster managed profiles";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart portmaster-managed-profiles.service";
    };
  };
}
