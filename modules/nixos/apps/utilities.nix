{ config, pkgs, ... }:

{
programs.zoom-us.enable = true;
programs.qgroundcontrol.enable = true;
  # Utilities and system tools
  environment.systemPackages = with pkgs; [
    wget
    lshw
    vulkan-tools
    mesa-demos #glx-info
    libva-utils
    powertop
    zoom-us
    #teams
    scrcpy
    libGL
    pciutils
    clinfo
    virtiofsd
    inkscape
    btop
    unrar
    wayland-utils
    xclicker
    usbutils
    nix-output-monitor
    libsysprof-capture
    gdk-pixbuf
    gdk-pixbuf-xlib
    libnotify
    xrgears
    kiwix
    v4l-utils
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    nicotine-plus
    fastfetch
    converseen
    servo
    normcap
    yt-dlp
    autotalent
    sqlite
    mediawriter
    wl-clipboard
    postman
    libGL
    libreoffice-qt-fresh
    onlyoffice-desktopeditors
    nss
    ckan
    immich-go
    kubectl
    signal-desktop
    kdePackages.gwenview
    kdePackages.discover
  ];

}
