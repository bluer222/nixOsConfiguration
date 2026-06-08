{ config, pkgs, ... }:

{
  services.portmaster = {
    enable = true;
    settings = {
      devmode = true; # UI at 127.0.0.1:817
      "filter/blockInternet" = true; # Strict default
      "filter/blockLAN" = true;      # Strict default
      "filter/blockInbound" = true;  # Strict default
    };

    managedProfiles = {
      # --- System Core ---
      nix = {
        name = "Nix";
        package = pkgs.nix;
        settings = { "filter/blockInternet" = false; };
      };
      
      systemd-resolved = {
        name = "systemd-resolved";
        identity.launcher = "systemd-resolved";
        settings = { "filter/blockInternet" = false; };
      };

      systemd-timesyncd = {
        name = "systemd-timesyncd";
        identity.launcher = "systemd-timesyncd";
        settings = { "filter/blockInternet" = false; };
      };

      # --- System Services ---
      geoclue = {
        name = "Geoclue";
        package = pkgs.geoclue2;
        settings = { "filter/blockInternet" = false; };
      };

      nsncd = {
        name = "nsncd";
        package = pkgs.nsncd;
        settings = { "filter/blockInternet" = false; };
      };

      fwupd = {
        name = "fwupd";
        package = pkgs.fwupd;
        settings = { "filter/blockInternet" = false; };
      };

      flatpak = {
        name = "Flatpak";
        package = pkgs.flatpak;
        settings = { "filter/blockInternet" = false; };
      };

      cups = {
        name = "CUPS";
        package = pkgs.cups;
        settings = {
          "filter/blockInternet" = false;
          "filter/blockLAN" = false;
          "filter/blockInbound" = false;
        };
      };

      ssh = {
        name = "SSH";
        package = pkgs.openssh;
        settings = { "filter/blockInternet" = false; };
      };

      # --- Essential Interactive Tools ---
      gemini-cli = {
        name = "Gemini CLI";
        package = pkgs.gemini-cli;
        settings = { "filter/blockInternet" = false; };
      };

      git = {
        name = "Git";
        package = pkgs.git;
        settings = { "filter/blockInternet" = false; };
      };

      curl = {
        name = "curl";
        identity.launcher = "curl";
        settings = { "filter/blockInternet" = false; };
      };

      wget = {
        name = "wget";
        identity.launcher = "wget";
        settings = { "filter/blockInternet" = false; };
      };

      # --- Browsers & Communication ---
      brave = {
        name = "Brave Browser";
        package = pkgs.brave;
        settings = { "filter/blockInternet" = false; };
      };

      zoom = {
        name = "Zoom";
        package = pkgs.zoom-us;
        settings = { "filter/blockInternet" = false; };
      };

      postman = {
        name = "Postman";
        package = pkgs.postman;
        settings = { "filter/blockInternet" = false; };
      };

      # --- Gaming & Streaming ---
      steam = {
        name = "Steam";
        package = pkgs.steam;
        settings = {
          "filter/blockInternet" = false;
          "filter/blockLAN" = false;
          "filter/blockInbound" = false; # Needed for Remote Play / Streaming
        };
      };

      lutris = {
        name = "Lutris";
        package = pkgs.lutris;
        settings = { "filter/blockInternet" = false; };
      };

      # --- Discovery & Synchronization ---
      kdeconnect = {
        name = "KDE Connect";
        package = pkgs.kdePackages.kdeconnect-kde;
        settings = {
          "filter/blockLAN" = false;
          "filter/blockInbound" = false;
        };
      };

      avahi = {
        name = "Avahi Daemon";
        identity.launcher = "avahi-daemon";
        settings = {
          "filter/blockLAN" = false;
          "filter/blockInbound" = false;
        };
      };

      # --- Specialized Tools ---
      proton-vpn = {
        name = "Proton VPN";
        package = pkgs.proton-vpn;
        settings = { "filter/blockInternet" = false; };
      };

      nicotine-plus = {
        name = "Nicotine+";
        package = pkgs.nicotine-plus;
        settings = {
          "filter/blockInternet" = false;
          "filter/blockInbound" = false; # P2P
        };
      };

      immich-go = {
        name = "Immich-go";
        package = pkgs.immich-go;
        settings = { "filter/blockInternet" = false; };
      };

      kiwix = {
        name = "Kiwix";
        package = pkgs.kiwix;
        settings = { "filter/blockInternet" = false; };
      };

      kubectl = {
        name = "kubectl";
        identity.launcher = "kubectl";
        settings = { "filter/blockInternet" = false; };
      };

      # --- Development Tools ---
      vscode = {
        name = "VS Code";
        package = pkgs.vscode;
        settings = { "filter/blockInternet" = false; };
      };

      android-studio = {
        name = "Android Studio";
        package = pkgs.android-studio;
        settings = { "filter/blockInternet" = false; };
      };

      arduino-ide = {
        name = "Arduino IDE";
        package = pkgs.arduino-ide;
        settings = { "filter/blockInternet" = false; };
      };

      # --- Security Research (Typically need unrestricted access) ---
      tor-browser = {
        name = "Tor Browser";
        package = pkgs.tor-browser;
        settings = { "filter/blockInternet" = false; };
      };

      nmap = {
        name = "nmap";
        package = pkgs.nmap;
        settings = {
          "filter/blockInternet" = false;
          "filter/blockLAN" = false;
        };
      };

      metasploit = {
        name = "Metasploit";
        package = pkgs.metasploit;
        settings = {
          "filter/blockInternet" = false;
          "filter/blockLAN" = false;
        };
      };
    };
  };
}
