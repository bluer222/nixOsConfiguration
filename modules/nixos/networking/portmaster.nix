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
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-systemd(-[^/]+)?/lib/systemd/systemd-timesyncd$")
        ];
        settings = allowInternet;
      };

      geoclue = {
        name = "Geoclue";
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-geoclue(-[^/]+)?/libexec/.geoclue-wrapped$")
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
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-brave(-[^/]+)?/opt/brave.com/brave/brave$")
        ];
        settings = allowInternetLANP2P;
      };

      brave-origin = {
        name = "Brave Origin";
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-brave-origin(-[^/]+)?/opt/brave.com/brave-origin/brave$")
        ];
        settings = allowInternetLANP2P;
      };

      google-chrome = {
        name = "Google Chrome";
        fingerprints = [
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
          (mkPathRegex "^/nix/store/[^/]+-electron-unwrapped-[^/]+/libexec/electron/electron$")
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
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-discover(-[^/]+)?/bin/.plasma-discover-wrapped$")
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
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-kdeconnect-kde(-[^/]+)?/bin/.kdeconnectd-wrapped$")
        ];
        settings = allowLANInbound;
      };

      avahi = {
        name = "Avahi Daemon";
        fingerprints = [
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
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-vscode(-[^/]+)?/lib/vscode/code$")
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
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-tor-browser(-[^/]+)?/share/tor-browser/TorBrowser/Tor/tor$")
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

      noctalia = {
        name = "Noctalia";
        packages = [ pkgs.noctalia ];
        settings = allowInternetP2P;
      };
    };
  };

  # Portmaster allowReplace keys profiles by fingerprint identity. When
  # fingerprints change, rebuilds leave duplicate "[NixOS] …" rows. If that
  # happens, soft-delete the dupes then reimport. Stable fingerprints → no-op.
  systemd.services.portmaster-cleanup-orphans =
    let
      managedNames = lib.mapAttrsToList (
        _: p: config.services.portmaster.profilePrefix + p.name
      ) config.services.portmaster.profiles;
      namesFile = pkgs.writeText "portmaster-managed-names" (
        lib.concatStringsSep "\n" managedNames + "\n"
      );
    in
    {
      description = "Remove duplicate NixOS-managed Portmaster profiles";
      after = [ "portmaster.service" ];
      before = [ "portmaster-managed-profiles.service" ];
      wants = [ "portmaster.service" ];
      requiredBy = [ "portmaster-managed-profiles.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "portmaster-cleanup-orphans" ''
          set -euo pipefail
          db="/var/lib/portmaster/databases/core/sqlite/db.sqlite"
          key_file="/var/lib/portmaster/config/nix-managed-profiles-api-key"
          names=${namesFile}

          if [ ! -f "$db" ] || [ ! -f "$key_file" ]; then
            exit 0
          fi

          ready=0
          for _ in $(${pkgs.coreutils}/bin/seq 1 60); do
            if ${pkgs.curl}/bin/curl --silent --fail --noproxy '*' --max-time 2 \
              http://127.0.0.1:817/api/v1/ping >/dev/null; then
              ready=1
              break
            fi
            ${pkgs.coreutils}/bin/sleep 1
          done
          if [ "$ready" -ne 1 ]; then
            echo "portmaster API not ready; skipping orphan cleanup" >&2
            exit 0
          fi

          now=$(${pkgs.coreutils}/bin/date +%s)
          # allowReplace keys by fingerprint identity, so fingerprint edits can
          # leave multiple rows with the same "[NixOS] …" name. Only wipe when
          # that has already happened (stable fingerprints → no-op on boot).
          dups=$(${pkgs.sqlite}/bin/sqlite3 "$db" "
            SELECT json_extract(value, '$.Name') AS name
            FROM records
            WHERE key LIKE 'profiles/local/%' AND deleted = 0
            GROUP BY name
            HAVING COUNT(*) > 1;
          ")
          if [ -z "$dups" ]; then
            exit 0
          fi

          count=0
          while IFS='|' read -r key name; do
            if ! ${pkgs.gnugrep}/bin/grep -Fxq "$name" "$names"; then
              continue
            fi
            # Only touch names that are actually duplicated.
            if ! ${pkgs.gnugrep}/bin/grep -Fxq "$name" <<<"$dups"; then
              continue
            fi
            esc=$(${pkgs.gnused}/bin/sed "s/'/''''/g" <<<"$key")
            ${pkgs.sqlite}/bin/sqlite3 "$db" \
              "UPDATE records SET deleted = $now, modified = $now WHERE key = '$esc';"
            count=$((count + 1))
          done < <(${pkgs.sqlite}/bin/sqlite3 "$db" "
            SELECT key, json_extract(value, '$.Name')
            FROM records
            WHERE key LIKE 'profiles/local/%' AND deleted = 0;
          ")

          if [ "$count" -eq 0 ]; then
            exit 0
          fi
          echo "soft-deleted $count duplicate NixOS-managed Portmaster profiles"

          key=$(${pkgs.coreutils}/bin/tr -d '\r\n' < "$key_file")
          ${pkgs.curl}/bin/curl --silent --fail --noproxy '*' --max-time 10 \
            -H "Authorization: Bearer $key" \
            -X POST http://127.0.0.1:817/api/v1/core/restart >/dev/null || true

          for _ in $(${pkgs.coreutils}/bin/seq 1 60); do
            if ${pkgs.curl}/bin/curl --silent --fail --noproxy '*' --max-time 2 \
              http://127.0.0.1:817/api/v1/ping >/dev/null; then
              exit 0
            fi
            ${pkgs.coreutils}/bin/sleep 1
          done
          echo "portmaster did not come back after restart" >&2
          exit 1
        '';
      };
    };
}
