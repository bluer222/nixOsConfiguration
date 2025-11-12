{ config, inputs, pkgs, lib, stdenv, ... }:

let
Mcontrolcenter = pkgs.callPackage ./mcontrolcenter.nix { };
thorium-browser = pkgs.callPackage ./thorium.nix { };

astronaut = pkgs.sddm-astronaut;

in
{
#some packages need to be system
environment.systemPackages = [ Mcontrolcenter pkgs.hyprland pkgs.monado-vulkan-layers pkgs.kwin-gestures.default ];

#input remaper
#services.input-remapper.enable = true;

services.flatpak.enable = true;
  programs.chromium = {
    enable = true;
    #set automatically
    #plasmaBrowserIntegrationPackage = pkgs.kdePackages.plasma-browser-integration;
    extraOpts = {
      "args" = "--enable-features=AcceleratedVideoDecodeLinuxZeroCopyGL,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder";
    };
  };
programs.gamescope.enable = true;
  #add nix-ld for dynamic executables
    programs.nix-ld.enable = true;
  #add steam
 programs.steam = {
 enable = true;
 remotePlay.openFirewall = true;
 localNetworkGameTransfers.openFirewall = true;
 dedicatedServer.openFirewall = true;
 #use igpu
   package = pkgs.steam.override {
    extraPkgs = pkgs: with pkgs; [
      intel-vaapi-driver
      libva
      libvdpau-va-gl
      vulkan-loader
      vulkan-tools
      mesa
      intel-media-driver
    ];
  };
 };
 #use igpu by default
 environment.variables = {
  __GLX_VENDOR_LIBRARY_NAME = "mesa";  # Avoids loading NVIDIA GLX
  LIBVA_DRIVER_NAME = "iHD";           # Use Intel VAAPI
  VDPAU_DRIVER = "va_gl";              # Use VAAPI for VDPAU
};

  #add quemu
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  programs.virt-manager.enable = true;
  programs.direnv.enable = true;
  programs.direnv.enableZshIntegration = true;

  programs.java.enable = true;
  programs.java.package = pkgs.jdk21;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.samm = {
    #user
    isNormalUser = true;
    home = "/home/samm";
    description = "Sam Merlin";
    extraGroups = [ "video" "networkmanager" "wheel" "ydotool" "audio" "i2c" "dialout" ];
    #add packages here if theres no config to add it
    packages = with pkgs; [
      kdePackages.kate
      libGL
      steam
      lutris
      kdePackages.partitionmanager
      burpsuite
      wget
      lshw
      vlc
      gparted
      vulkan-tools
      xdotool
      wineWowPackages.stagingFull
      mesa-demos #glx-info
      github-desktop
      git
      protonvpn-gui
      tor-browser
      postgresql_15
      vscode
      #printrun
      libva-utils
      powertop
      zoom-us
      cups
      godot_4
      jpexs
      scrcpy
      libGL
      obs-studio
      audacity
      kazam
      nmap
      metasploit
      #nmapsi4
      kdePackages.filelight
      jdk21
      libuuid
      #blender
      signal-desktop
      android-tools
      mangohud
      kdePackages.kdenlive
      kdePackages.kde-gtk-config
      protontricks
      unrar
      libuuid
      nodejs_20
      wayland-utils
      pciutils
      clinfo
      #vm shared folder
      virtiofsd
      #icons tuff
      android-studio
      inkscape
      kdePackages.baloo
      #inputs.kwin-effects-forceblur.packages.${pkgs.system}.default
      kdePackages.oxygen-sounds
      kdePackages.qtvirtualkeyboard
      kdePackages.qtstyleplugin-kvantum
      btop
      #ydotool
      alsa-utils
      gcc14
mamba-cpp

    google-chrome
     #for swarmui
     dotnet-sdk_8
     kdePackages.kolourpaint
kdePackages.krecorder
neovim

ffmpeg-full
#hyperland stuff
kitty
#anyrun
#hyprlandPlugins.hyprscroller
go
vnstat
flatpak
kdePackages.ghostwriter
nss
ddcutil
kdePackages.isoimagewriter
#install themes
ocs-url
kde-rounded-corners
ddrescue
xclicker
wireshark-qt
usbutils
nix-output-monitor
#questpircay
#k\pkgs.glaumar_repo.qrookie
#vr
libsysprof-capture
gdk-pixbuf
gdk-pixbuf-xlib
libnotify
xrgears
wlx-overlay-s
gnumake
kiwix
#normcap
cura-appimage
v4l-utils
qview
#spellcheck
   aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science

    kicad

    upscayl
    nicotine-plus
fastfetch
converseen
arduino-ide
#python314
kdePackages.kmail
kdePackages.kmail-account-wizard
libreoffice-qt6-fresh
python312
python312Packages.matplotlib
gimp3
qview
#vr desktop?
wlx-overlay-s
winetricks
devenv
direnv
kdePackages.keysmith
servo
];
  };
  programs.partition-manager.enable = true;
  #makes x11 over ssh work
  programs.ssh.setXAuthLocation = true;

programs.wireshark.enable = true;

nixpkgs.config.permittedInsecurePackages = [];
nixpkgs.config.allowBroken = true;

  #services.netdata.enable = true;
#programs.ydotool.enable = true;
#steelseries
#KERNEL=="hidraw*", ATTRS{idVendor}=="1038", MODE="0666"

#services.udev.extraRules = ''
#SUBSYSTEM=="usb", MODE="0666"
#     ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0b95", ATTR{idProduct}=="1790", \
#    RUN+="${pkgs.bash}/bin/bash -c 'echo 0b95 1790 > /sys/bus/usb/drivers/cdc_ncm/unbind; echo 0b95 1790 > /sys/bus/usb/drivers/ax88179_178a/bind'"
#'';
}
