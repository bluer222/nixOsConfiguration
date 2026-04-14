{ config, inputs, pkgs, lib, stdenv, ... }:

let
  Mcontrolcenter = pkgs.callPackage ./mcontrolcenter.nix { };
in
{
  #some packages need to be system
  environment.systemPackages = [ Mcontrolcenter ];

  #input remaper
  #services.input-remapper.enable = true;

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

  #firmware updates with discover
  services.fwupd.enable = true;

  #add quemu
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  programs.virt-manager.enable = true;
  programs.direnv.enable = true;
  programs.direnv.enableZshIntegration = true;

  #waydroid
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;

  programs.java.enable = true;
  programs.java.package = pkgs.jdk21;

  programs.obs-studio.enable = true;
  #programs.obs-studio.enableVirtualCamera = true;
  #cant do above bc of howdy
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.extraModprobeConfig = ''options v4l2loopback devices=1 video_nr=3 card_label="OBS Cam" exclusive_caps=1'';
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.samm = {
    #user
    isNormalUser = true;
    home = "/home/samm";
    description = "Sam Merlin";
    extraGroups = [ "video" "networkmanager" "wheel" "ydotool" "audio" "i2c" "dialout" "docker" ];
    #add packages here if theres no config to add it
    packages = with pkgs; [
      kdePackages.kate
      libGL
      steam
      lutris
      burpsuite
      wget
      lshw
      vlc
      gparted
      vulkan-tools
      mesa-demos #glx-info
      git
      proton-vpn
      tor-browser
      vscode
      libva-utils
      powertop
      zoom-us
      cups
      godot_4
      scrcpy
      libGL
      audacity
      nmap
      metasploit
      rustscan
      kdePackages.filelight
      libuuid
      blender
      flare-signal
      android-tools
      mangohud
      kdePackages.kde-gtk-config
      unrar
      wayland-utils
      pciutils
      clinfo
      #vm shared folder
      virtiofsd
      #icons tuff
      android-studio
      inkscape
      #file indexing(its really bad)
      kdePackages.baloo
      #inputs.kwin-effects-forceblur.packages.${pkgs.system}.default
      kdePackages.oxygen-sounds
      btop
      mamba-cpp
      #paint and recorder app
      kdePackages.kolourpaint
      kdePackages.krecorder
      #how to exit?
      neovim
      ffmpeg-full
      flatpak
      kdePackages.ghostwriter
      nss
      ddcutil
      kdePackages.isoimagewriter
      #install themes
      ocs-url
      (kde-rounded-corners.overrideAttrs (oldAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "matinlotfali";
            repo = "KDE-Rounded-Corners";
            rev = "2cf9329b31b3152e5513f7069c4bb11c765fdc6e";
            sha256 = "sha256-mVoLCnpWHC2qDouO97n2cmxiewLCokjnWl1I9tnkIN4=";
          };
        }))
      ddrescue
      xclicker
      wireshark
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
      gnumake
      kiwix
      #normcap
      cura-appimage
      v4l-utils
      #spellcheck
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      kicad-small
      upscayl
      nicotine-plus
      fastfetch
      converseen
      arduino-ide
      kdePackages.kmail
      kdePackages.kmailtransport
      kdePackages.kmail-account-wizard
      gimp3
      qview
      #vr desktop?
      wayvr
      winetricks
      devenv
      direnv
      kdePackages.keysmith
      servo
      inputs.affinity-nix.packages.x86_64-linux.v3
      onlyoffice-desktopeditors
      normcap
      yt-dlp
      autotalent

      digikam
      #pkgs.comfy-ui-cuda
      brave
      kdePackages.umbrello
      konsave
      kdePackages.karousel
      caligula
      #fix chinese jap, korean, chars not showing
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      libreoffice-qt-fresh
      wl-clipboard
      postman
      sqlite
      tesseract
      mediawriter
      (pkgs.kdePackages.spectacle.override {
        tesseractLanguages = [ "eng" ];
      })
    ];
  };
  programs.steam.protontricks.enable = true;

  programs.kde-pim.kmail = true;

  programs.partition-manager.enable = true;
  #makes x11 over ssh work
  programs.ssh.setXAuthLocation = true;

  programs.wireshark.enable = true;

  nixpkgs.config.permittedInsecurePackages = [];
  nixpkgs.config.allowBroken = true;

  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker.daemon.settings.features.cdi = true;
  #virtualisation.docker.enableNvidia = true;


  #services.netdata.enable = true;
  #programs.ydotool.enable = true;
  #steelseries
  #KERNEL=="hidraw*", ATTRS{idVendor}=="1038", MODE="0666"

  services.udev.extraRules = ''
    # ZED Camera
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", MODE="0666"
    KERNEL=="video*", ATTRS{idVendor}=="2b03", MODE="0666"
  '';
  #services.udev.extraRules = ''
  #SUBSYSTEM=="usb", MODE="0666"
  #     ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0b95", ATTR{idProduct}=="1790", \
  #    RUN+="${pkgs.bash}/bin/bash -c 'echo 0b95 1790 > /sys/bus/usb/drivers/cdc_ncm/unbind; echo 0b95 1790 > /sys/bus/usb/drivers/ax88179_178a/bind'"
  #'';
}
