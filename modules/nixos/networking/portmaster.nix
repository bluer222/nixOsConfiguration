{ config, pkgs, lib, ... }:

let
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
  allowInternetLANP2P = mkRule {
    internet = true;
    lan = true;
    p2p = true;
  };
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
  allowAll = mkRule {
    internet = true;
    lan = true;
    inbound = true;
    p2p = true;
  };
in
{
  services.portmaster = {
    enable = true;
    profilePrefix = "[NixOS] ";
    settings = {
      devmode = true; # UI at 127.0.0.1:817
      # Block everything by default; declarative profiles grant explicit per-app access.
      "filter/blockInternet" = true;
      "filter/blockLAN" = true;
      "filter/blockInbound" = true;
      "filter/blockP2P" = true;
    };

    profiles = {
      nix = {
        name = "Nix";
        packages = [ pkgs.nix ];
        settings = allowInternet;
      };

      timesyncd = {
        name = "timesyncd";
        fingerprints = [
          # /nix/store/r6sz8p6sd6c73fp9z8nzl04dri7lyx8n-systemd-261.1/lib/systemd
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-systemd(-[^/]+)?/lib/systemd/systemd-timesyncd$")
        ];
        settings = allowInternet;
      };

      geoclue = {
        name = "Geoclue";
        fingerprints = [
          # /nix/store/8zyh4lvbg4wkdfmkmcnc9lsxpa98h45d-geoclue-2.8.1/libexec
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-geoclue(-[^/]+)?/libexec/.geoclue-wrapped")
        ];
        settings = allowInternetP2P;
      };

      nsncd = {
        name = "nsncd";
        packages = [ pkgs.nsncd ];
        settings = allowInternet;
      };

      fwupd = {
        name = "fwupd";
        packages = [ pkgs.fwupd ];
        settings = allowInternetP2P;
      };

      flatpak = {
        name = "Flatpak";
        packages = [ pkgs.flatpak ];
        settings = allowInternet;
      };

      cups = {
        name = "CUPS";
        packages = [ pkgs.cups ];
        settings = allowInternetLANInbound;
      };

      cups-browsed = {
        name = "CUPS Browsed";
        packages = [ pkgs.cups-browsed ];
        settings = allowLAN;
      };

      ssh = {
        name = "SSH";
        packages = [ pkgs.openssh ];
        settings = allowInternetLAN;
      };

      gemini-cli = {
        name = "Gemini CLI";
        packages = [ pkgs.gemini-cli ];
        settings = allowInternet;
      };

      cursor-agent = {
        name = "Cursor Agent";
        packages = [ pkgs.cursor-cli ];
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-cursor-cli-[^/]+/share/cursor-agent/node$")
        ];
        settings = allowInternetP2P;
      };

      codex = {
        name = "Codex";
        packages = [ pkgs.codex ];
        fingerprints = [
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.vscode/extensions/openai.chatgpt.*")
        ];
        settings = allowInternetP2P;
      };

      git = {
        name = "Git";
        fingerprints = [
          # /nix/store/6f0qqak4qbcrbw4f750phr88c9yhpf5s-git-2.55.0/libexec/git-core
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-git(-[^/]+)?/libexec/git-core.*")
        ];
        settings = allowInternetP2P;
      };

      curl = {
        name = "curl";
        packages = [ pkgs.curl ];
        settings = allowInternet;
      };

      wget = {
        name = "wget";
        packages = [ pkgs.wget ];
        settings = allowInternetP2P;
      };

      brave = {
        name = "Brave Browser";
        fingerprints = [
          # /nix/store/x6fs3l8zsh60az8hd7f89478x1yv1jpg-brave-1.93.129/opt/brave.com/brave
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-brave(-[^/]+)?/opt/brave.com/brave/brave$")
        ];
        settings = allowInternetLANP2P;
      };

      brave-origin = {
        name = "Brave Origin";
        fingerprints = [
          # /nix/store/w5pnxnw5bfyijnfi5zq7119scki0g9vw-brave-origin-1.93.129/opt/brave.com/brave-origin
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-brave-origin(-[^/]+)?/opt/brave.com/brave-origin/brave$")
        ];
        settings = allowInternetLANP2P;
      };

      google-chrome = {
        name = "Google Chrome";
        fingerprints = [
          #/nix/store/gfmwds1c4smb53nmrn3h4424gpg2lsa1-google-chrome-151.0.7922.75/share/google/chrome
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-google-chrome(-[^/]+)?/share/google/chrome/chrome$")
        ];
        settings = allowInternetLANP2P;
      };

      zoom = {
        name = "Zoom";
        packages = [ pkgs.zoom-us ];
        settings = allowInternetInbound;
      };

      signal = {
        name = "Signal Desktop";
        packages = [ pkgs.signal-desktop ];
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-electron-unwrapped-[^/]+/libexec/electron$")
        ];
        settings = allowInternetP2P;
      };

      postman = {
        name = "Postman";
        packages = [ pkgs.postman ];
        settings = allowInternet;
      };

      steam = {
        name = "Steam";
        packages = [ pkgs.steam ];
        fingerprints = [
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.local/share/Steam/.*")
        ];
        settings = allowAll;
      };

      lutris = {
        name = "Lutris";
        packages = [ pkgs.lutris ];
        settings = allowInternet;
      };

      godot = {
        name = "Godot Engine";
        packages = [ pkgs.godot_4 ];
        settings = allowInternet;
      };

      winetricks = {
        name = "Winetricks";
        packages = [ pkgs.winetricks ];
        settings = allowInternet;
      };

      obs-studio = {
        name = "OBS Studio";
        packages = [ pkgs.obs-studio ];
        settings = allowInternetLANInbound;
      };

      discover = {
        name = "Discover";
        fingerprints = [
          #/nix/store/rpgg0cz14dpn7djfkmd56h47jkkx80nw-discover-6.7.4/bin
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-discover(-[^/]+)?/bin/.plasma-discover-wrapped$")
          #kioworker:  /nix/store/c19br0qpnzyncml49khiasz4j49jrj99-kio-6.28.0/libexec/kf6
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-kio(-[^/]+)?/libexec/kf6$")
        ];
        settings = allowInternetP2P;
      };



      vlc = {
        name = "VLC Media Player";
        packages = [ pkgs.vlc ];
        settings = allowInternetLAN;
      };

      wivrn = {
        name = "WiVRn VR Streamer";
        packages = [ pkgs.wivrn ];
        settings = allowInternetLANInbound;
      };

      kdeconnect = {
        name = "KDE Connect";
        fingerprints = [
          # /nix/store/cqv9kvkx8zs4b7kmjnp5gx16qj4fyhd0-kdeconnect-kde-26.04.3/bin
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-kdeconnect-kde(-[^/]+)?/bin/.kdeconnectd-wrapped$")
        ];
        settings = allowLANInbound;
      };

      avahi = {
        name = "Avahi Daemon";
        fingerprints = [
          #/nix/store/15g69mx7za6sazxmn2hiz3x8dp40cs48-avahi-0.8/bin/avahi-daemon
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-avahi(-[^/]+)?/bin/avahi-daemon$")
        ];
        settings = allowLANInbound;
      };

      copilot = {
        name = "GitHub Copilot";
        packages = [ pkgs.github-copilot-cli ];
        settings = allowInternetP2P;
      };

      proton-vpn = {
        name = "Proton VPN";
        packages = [ pkgs.proton-vpn ];
        settings = allowInternet;
      };

      nicotine-plus = {
        name = "Nicotine+";
        packages = [ pkgs.nicotine-plus ];
        settings = allowInternetInbound;
      };

      immich-go = {
        name = "Immich-go";
        packages = [ pkgs.immich-go ];
        settings = allowInternet;
      };

      kiwix = {
        name = "Kiwix";
        packages = [ pkgs.kiwix ];
        settings = allowInternet;
      };

      kubectl = {
        name = "kubectl";
        packages = [ pkgs.kubectl ];
        settings = allowInternet;
      };

      vscode = {
        name = "VS Code";
        fingerprints = [
          # /nix/store/g9bmnqasp0w164216m4z53wpbssmg3s4-vscode-1.130.0/lib/vscode
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-vscode-1.130.0/lib/vscode/code$")
        ];
        settings = allowInternetP2P;
      };

      android-studio = {
        name = "Android Studio";
        packages = [ pkgs.android-studio ];
        settings = allowInternetP2P;
      };

      arduino-ide = {
        name = "Arduino IDE";
        packages = [ pkgs.arduino-ide ];
        settings = allowInternet;
      };

      neovim = {
        name = "Neovim";
        packages = [ pkgs.neovim ];
        settings = allowInternet;
      };

      antigravity = {
        name = "Antigravity AI Agent";
        packages = [ pkgs.antigravity-ide-fhs pkgs.antigravity-cli ];
        settings = allowInternet;
      };

      docker = {
        name = "Docker";
        packages = [ pkgs.docker ];
        settings = allowInternetLAN;
      };

      qgroundcontrol = {
        name = "QGroundControl";
        packages = [ pkgs.qgroundcontrol ];
        settings = allowInternetLANInbound;
      };

      scrcpy = {
        name = "scrcpy";
        packages = [ pkgs.scrcpy ];
        settings = allowInternetLANInbound;
      };

      servo = {
        name = "Servo Browser";
        packages = [ pkgs.servo ];
        settings = allowInternet;
      };

      yt-dlp = {
        name = "yt-dlp";
        packages = [ pkgs.yt-dlp ];
        settings = allowInternet;
      };

      mediawriter = {
        name = "Fedora Media Writer";
        packages = [ pkgs.mediawriter ];
        settings = allowInternet;
      };

      onlyoffice = {
        name = "ONLYOFFICE";
        packages = [ pkgs.onlyoffice-desktopeditors ];
        settings = allowInternet;
      };

      ocs-url = {
        name = "ocs-url";
        packages = [ pkgs.ocs-url ];
        settings = allowInternet;
      };

      ckan = {
        name = "CKAN Mod Manager";
        packages = [ pkgs.ckan ];
        settings = allowInternet;
      };

      digikam = {
        name = "DigiKam";
        packages = [ pkgs.digikam ];
        settings = allowInternet;
      };

      cura = {
        name = "Cura Slicer";
        packages = [ pkgs.cura-appimage ];
        settings = allowInternetLANInbound;
      };

      tor-browser = {
        name = "Tor Browser";
        fingerprints = [
          #/nix/store/pj67yxvxz0czg48i2vkg5rwgfnlcr3dn-tor-browser-15.0.19/share/tor-browser/TorBrowser/Tor
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-tor-browser-15.0.19/share/tor-browser/TorBrowser/Tor/tor$")
        ];
        settings = allowInternetP2P;
      };

      nmap = {
        name = "nmap";
        packages = [ pkgs.nmap ];
        settings = allowInternetLAN;
      };

      metasploit = {
        name = "Metasploit";
        packages = [ pkgs.metasploit ];
        settings = allowInternetLAN;
      };

      burpsuite = {
        name = "Burp Suite";
        packages = [ pkgs.burpsuite ];
        settings = allowInternetLANInbound;
      };

      rustscan = {
        name = "RustScan";
        packages = [ pkgs.rustscan ];
        settings = allowInternetLAN;
      };

      kmail = {
        name = "KMail";
        packages = [ pkgs.kdePackages.kmail ];
        settings = allowInternet;
      };

      automatic-timezoned = {
        name = "Automatic Timezoned";
        packages = [ pkgs.automatic-timezoned ];
        settings = allowInternet;
      };

      waydroid = {
        name = "Waydroid";
        packages = [ pkgs.waydroid-nftables ];
        settings = allowInternetLANInbound;
      };

      twintaillauncher = {
        name = "Twintail Launcher";
        fingerprints = [
          (mkPathEquals "/app/bin/twintaillauncher")
          (mkPathRegex "^/home/samm/.var/app/app.twintaillauncher.ttl/.*")
        ];
        settings = allowInternet;
      };

      android-java = {
        name = "Java for android studio";
        fingerprints = [
          (mkPathRegex "^/home/samm/.jdks/.*")
        ];
        settings = allowInternet;
      };

      webkit-network-process = {
        name = "WebKit Network Process";
        fingerprints = [
          (mkPathEquals "/usr/libexec/webkit2gtk-4.1/WebKitNetworkProcess")
        ];
        settings = allowInternet;
      };
    };
  };
}
