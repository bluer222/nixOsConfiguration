{ config, pkgs, ... }:

{
  # Utilities and system tools
  environment.systemPackages = with pkgs; [
    wget
    lshw
    gparted
    vulkan-tools
    mesa-demos #glx-info
    libva-utils
    powertop
    zoom-us
    scrcpy
    libGL
    pciutils
    clinfo
    virtiofsd
    inkscape
    kdePackages.baloo
    kdePackages.oxygen-sounds
    btop
    mamba-cpp
    kdePackages.kde-gtk-config
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
    tesseract
    mediawriter
    wl-clipboard
    postman
    kdePackages.kate
    libGL
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    libreoffice-qt-fresh
    onlyoffice-desktopeditors
    brave
    konsave
    kdePackages.karousel
    caligula
    kdePackages.isoimagewriter
    ocs-url
    digikam
    ddrescue
    ddcutil
    kdePackages.ghostwriter
    nss
    (pkgs.spectacle.override {
      tesseractLanguages = [ "eng" ];
    })
  ];
}
