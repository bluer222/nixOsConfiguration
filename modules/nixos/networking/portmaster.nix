{ config, inputs, pkgs, lib, ... }:

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

   mkFlatpakEquals = value: {
    type = "tag";
    operation = "equals";
    key = "Flatpak ID";
    value = value;
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
  };
  allowInternetInboundP2P = mkRule {
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
    # Keep core + menu launcher; drop the packaged tray autostart without rebuilding.
    package = pkgs.symlinkJoin {
      inherit (pkgs.portmaster) name pname version meta;
      paths = [ pkgs.portmaster ];
      postBuild = ''
        rm -rf "$out/etc"
      '';
    };
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

      qemu-user = {
        name = "QEMU User";
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-qemu-user(-[^/]+)?/bin/qemu-[^/]+$")
        ];
        settings = allowInternetP2P;
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
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-geoclue(-[^/]+)?/libexec/\\.geoclue-wrapped$")
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
        fingerprints = [
          # /nix/store/yhdklphh417r1g4cg34h4xw9bwvl194h-fwupd-2.1.6/bin/.fwupdmgr-wrapped
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-fwupd(-[^/]+)?/bin/\\.fwupdmgr-wrapped$")
        ];
        settings = allowInternetP2P;
      };

      flatpak = {
        name = "Flatpak";
        packages = [ pkgs.flatpak ];
        fingerprints = [
          (mkPathRegex "^/nix/store/1lqd4p641h1hn4gn43qjnb1v5w2iy12l-flatpak(-[^/]+)?/bin/\.flatpak-wrapped$")
        ];
        settings = allowInternetP2P;
      };


      cups = {
        name = "CUPS";
        packages = [ pkgs.cups ];
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-cups(-[^/]+)?/lib/cups/backend/ipp$")
        ];
        settings =  allowLANInbound;
      };

      cups-browsed = {
        name = "CUPS Browsed";
        packages = [ pkgs.cups-browsed ];
        settings = allowLANInbound;
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
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-cursor-agent-[^/]+/share/cursor-agent/node$")
        ];
        settings = allowInternetP2P;
      };
      claude-code = {
        name = "Claude Code";
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-claude-code-[^/]+/bin/\\.claude-wrapped$")
        ];
        settings = allowInternetP2P;
      };

      opencode = {
        name = "Opencode";
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-opencode-[^/]+/bin/\\.opencode-wrapped$")
        ];
        settings = allowInternetP2P;
      };

      codex = {
        name = "Codex";
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-codex-[^/]+/libexec/codex/bin/codex$")
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.vscode/extensions/openai.chatgpt-[^/]+-linux-x64/bin/linux-x86_64/codex$")
        ];
        settings = allowInternetP2P;
      };

      t3-code = {
        name = "T3 Code";
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-nodejs-slim-[^/]+/bin/node$")
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.t3/tools/cloudflared/[^/]+/linux-x64/cloudflared$")
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.t3/runtime/versions/[^/]+/t3$")
        ];
        settings = allowInternetP2P;
      };

      t3-browser = {
        name = "T3 Browser";
        fingerprints = [
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.t3/tools/chrome-headless-shell/linux64/[^/]+/chrome-headless-shell$")
        ];
        settings = allowInternetLAN;
      };

      zcode = {
        name = "ZCode";
        packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.zcode ];
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-zcode-[^/]+/lib/ZCode/zcode$")
        ];
        settings = allowInternetP2P;
      };

      vmware-natd = {
        name = "VMware NATD";
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-vmware-workstation-[^/]+/bin/vmnet-natd$")
        ];
        settings = allowInternetLANP2P;
      };

      muse = {
        name = "Muse Code";
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-muse-code-[^/]+/bin/muse$")
        ];
        settings = allowInternetP2P;
      };

      grok-bot = {
        name = "Grok Bot";
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-grok-bot-[^/]+/lib/grok-bot/grok-bot$")
        ];
        settings = allowInternetP2P;
      };
      
      sober = {
        name = "Sober";
        fingerprints = [
          (mkFlatpakEquals "org.vinegarhq.Sober")
          (mkPathRegex "^/app/bin/sober$")
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
        settings = allowInternetP2P;
      };

      wget = {
        name = "wget";
        packages = [ pkgs.wget ];
        settings = allowInternetP2P;
      };

      brave = {
        name = "Brave Browser";
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-brave(-[^/]+)?/opt/brave\\.com/brave/brave$")
        ];
        settings = allowInternetLANP2P;
      };

      brave-origin = {
        name = "Brave Origin";
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-brave-origin(-[^/]+)?/opt/brave\\.com/brave-origin/brave$")
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
        settings = allowInternetInboundP2P;
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

      lutris-wine = {
        name = "Lutris Wine";
        fingerprints = [
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.local/share/lutris/runners/wine/[^/]+-lutris-wine-[^/]+/files/bin/wineserver$")
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.local/share/lutris/runners/wine/[^/]+-lutris-wine-[^/]+/bin/wineserver$")
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.local/share/lutris/runners/wine/[^/]+-lutris-wine-[^/]+/files/lib/wine/x86_64-unix/(wine64-preloader|wine-preloader)$")
        ];
        settings = allowInternetP2P;
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

      wine = {
        name = "Wine";
        #wineWow64Packages.stableFull for fusion
        fingerprints = [
          (mkPathRegex "^/nix/store/[^/]+-wine-wow64-[^/]+/bin/wineserver$")
        ];
        settings = allowInternetP2P;
      };

      fusion360 = {
        name = "Fusion 360";
        fingerprints = [
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.local/share/fusion360/fusion-wine-build/bin/wineserver$")
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.local/share/fusion360/fusion-wine-build/lib/wine/x86_64-unix/wine-preloader$")
          (mkPathRegex "^/nix/store/[^/]+-wine-wow64-[^/]+/lib/wine/x86_64-unix/wine-preloader$")
        ];
        settings = allowInternetP2P;
      };

      obs-studio = {
        name = "OBS Studio";
        packages = [ pkgs.obs-studio ];
        settings = allowInternetLANInbound;
      };

      discover = {
        name = "Discover";
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-discover(-[^/]+)?/bin/\\.plasma-discover-wrapped$")
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-kio(-[^/]+)?/libexec/kf6/\\.kioworker-wrapped$")
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
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-kdeconnect-kde(-[^/]+)?/bin/\\.kdeconnectd-wrapped$")
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
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-python3-[^/]+/bin/python3\\.[0-9]+$")
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-openvpn-[^/]+/bin/openvpn$")
        ];
        settings = allowInternetP2P;
      };

      nicotine-plus = {
        name = "Nicotine+";
        packages = [ pkgs.nicotine-plus ];
        settings = allowInternetInboundP2P;
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

      zed = {
        name = "Zed";
        fingerprints = [
          # FHS wrapper execs this; Portmaster sees the unwrapped binary.
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-zed-editor(-[^/]+)?/libexec/\\.zed-editor-wrapped$")
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

      antigravity-acp = {
        name = "Antigravity ACP (T3 Code)";
        fingerprints = [
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.t3/tools/antigravity-acp/[^/]+/versions/[^/]+/(agy_acp_server\\.par|localharness_external)$")
        ];
        settings = allowInternetP2P;
      };

      antigravity-ide = {
        name = "Antigravity IDE";
        packages = [ pkgs.antigravity-ide-fhs ];
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-antigravity-ide(-[^/]+)?/lib/antigravity-ide/antigravity-ide$")
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-antigravity-ide(-[^/]+)?/lib/antigravity-ide/resources/app/extensions/antigravity/bin/language_server_linux_x64$")
        ];
        settings = allowInternetP2P;
      };

      antigravity-cli = {
        name = "Antigravity CLI";
        fingerprints = [
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.gemini/bin/agy$")
        ];
        settings = allowInternetP2P;
      };

      docker = {
        name = "Docker";
        packages = [ pkgs.docker ];
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-moby(-[^/]+)?/libexec/docker/dockerd$")
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-docker-buildx(-[^/]+)?/libexec/docker/cli-plugins/docker-buildx$")
        ];
        settings = allowInternetLANP2P;
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

      github = {
        name = "GitHub CLI";
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-gh(-[^/]+)?/bin/\\.gh-wrapped$")
        ];
        settings = allowInternetP2P;
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

      aerion = {
        name = "Aerion";
        fingerprints = [
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-aerion(-[^/]+)?/bin/\\.aerion-wrapped$")
        ];
        settings = allowInternetP2P;
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
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.var/app/app\\.twintaillauncher\\.ttl/.*")
        ];
        settings = allowInternet;
      };

      android-java = {
        name = "Java for android studio";
        fingerprints = [
          (mkPathRegex "^${lib.escapeRegex config.users.users.samm.home}/\\.jdks/.*")
        ];
        settings = allowInternet;
      };

      webkit-network-process = {
        name = "WebKit Network Process";
        fingerprints = [
          (mkPathEquals "/usr/libexec/webkit2gtk-4.1/WebKitNetworkProcess")
          (mkPathRegex "^/nix/store/[a-z0-9]{32}-webkitgtk(-[^/]+)?/libexec/webkit2gtk-4\\.1/WebKitNetworkProcess$")
        ];
        settings = allowInternetP2P;
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
