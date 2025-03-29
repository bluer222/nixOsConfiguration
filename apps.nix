{ config, inputs, pkgs, lib, stdenv, ... }:

let
#Mcontrolcenter = pkgs.callPackage ./mcontrolcenter.nix { };
thorium-browser = pkgs.callPackage ./thorium.nix { };

astronaut = pkgs.sddm-astronaut;

in
{
#some packages need to be system
environment.systemPackages = [ pkgs.hyprland pkgs.monado-vulkan-layers pkgs.kwin-gestures.default ];

#input remaper
services.input-remapper.enable = true;

services.flatpak.enable = true;

programs.gamescope.enable = true;
  #add nix-ld for dynamic executables
    programs.nix-ld.enable = true;
  #add steam
 programs.steam = {
 enable = true;
 remotePlay.openFirewall = true;
 localNetworkGameTransfers.openFirewall = true;
 dedicatedServer.openFirewall = true;
 };
  #add quemu
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  programs.virt-manager.enable = true;

  programs.java.enable = true;
  programs.java.package = pkgs.jdk21;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.samm = {
    #user
    isNormalUser = true;
    home = "/home/samm";
    description = "Sam Merlin";
    extraGroups = [ "networkmanager" "wheel" "ydotool" "audio" "i2c" ];
    #add packages here if theres no config to add it
    packages = with pkgs; [
      kdePackages.kate
      steam
      lutris
      kdePackages.partitionmanager
      burpsuite
      wget
      lshw
      gparted
      vulkan-tools
      xdotool
      wineWowPackages.stagingFull
      glxinfo
      github-desktop
      git
      protonvpn-gui
      tor-browser-bundle-bin
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
      nmapsi4
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
      python3
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
      mcontrolcenter
      alsa-utils
      gcc14
      python312Packages.conda
     thorium-browser
     #for swarmui
     dotnet-sdk_8
     kdePackages.kolourpaint
kdePackages.krecorder
neovim

ffmpeg-full
#hyperland stuff
kitty
anyrun
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
pkgs.glaumar_repo.qrookie
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
];
  };
  programs.partition-manager.enable = true;
  #makes x11 over ssh work
  programs.ssh.setXAuthLocation = true;

programs.wireshark.enable = true;
  #services.netdata.enable = true;
#programs.ydotool.enable = true;
#steelseries
#KERNEL=="hidraw*", ATTRS{idVendor}=="1038", MODE="0666"

services.udev.extraRules = ''
SUBSYSTEM=="usb", MODE="0666"
'';
}
