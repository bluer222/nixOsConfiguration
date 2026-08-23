{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/home/niri/default.nix
  ];

  home = {
    username = "samm";
    homeDirectory = "/home/samm";
    stateVersion = "25.11";

    packages = with pkgs; [
      brave-origin
    ];
  };

  # Pin Brave to the KWallet key store on every launcher-based launch.
  # Overrides both .desktop files shipped by the brave-origin package.
  xdg.desktopEntries = {
    brave-origin = {
      name = "Brave Origin";
      genericName = "Web Browser";
      exec = "brave-origin --password-store=kwallet6 %U";
      icon = "brave-origin";
      startupWMClass = "brave-origin";
      terminal = false;
      categories = [ "Network" "WebBrowser" ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/pdf"
        "application/xhtml+xml"
        "application/xhtml_xml"
        "application/xml"
        "application/rss+xml"
        "application/rdf+xml"
        "image/gif"
        "image/jpeg"
        "image/png"
        "image/webp"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/chromium"
      ];
      actions = {
        new-window.exec = "brave-origin --password-store=kwallet6";
        new-private-window.exec = "brave-origin --password-store=kwallet6 --incognito";
      };
    };
    "com.brave.Origin" = {
      name = "Brave Origin";
      genericName = "Web Browser";
      exec = "brave-origin --password-store=kwallet6 %U";
      icon = "brave-origin";
      startupWMClass = "brave-origin";
      terminal = false;
      categories = [ "Network" "WebBrowser" ];
      actions = {
        new-window.exec = "brave-origin --password-store=kwallet6";
        new-private-window.exec = "brave-origin --password-store=kwallet6 --incognito";
      };
    };
  };

  programs.home-manager.enable = true;
}
