{ config, inputs, pkgs, lib, stdenv, ... }:

{
  #some packages need to be system
  environment = {
    systemPackages = [ 
    ];
    variables = {
      __GLX_VENDOR_LIBRARY_NAME = "mesa";  # Avoids loading NVIDIA GLX
      LIBVA_DRIVER_NAME = "iHD";           # Use Intel VAAPI
      VDPAU_DRIVER = "va_gl";              # Use VAAPI for VDPAU
    };
  };

  services = {
    flatpak.enable = true;
    fwupd.enable = true;
    udev.extraRules = ''
      # ZED Camera
      SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", MODE="0666"
      KERNEL=="video*", ATTRS{idVendor}=="2b03", MODE="0666"
      ACTION=="add", SUBSYSTEM=="leds", KERNEL=="platform::*mute", MODE="0775", GROUP="audio", ATTR{brightness}="0664"
    '';
  };

  #msi ec 
  systemd.tmpfiles.rules = [
    "z /sys/devices/platform/msi-ec/* 0664 root wheel - -"  #msi ec
  ];


  programs = {
    gamescope.enable = true;
    #add nix-ld for dynamic executables
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
        glib       # for libglib-2.0.so.0 and libgobject-2.0.so.0
        gmp        # for libgmp.so.10
        libGL      # for libGL.so.1
        libGLU     # for libGLU.so.1
        curl       # for libcurl.so.4
        gcc.cc.lib # for libgomp.so.1 and libstdc++.so.6
        zlib       # for libz.so.1
        libkrb5    # for libgssapi_krb5.so.2
        libxcb
        libxcb-cursor
        libxcb-image
        libxcb-keysyms
        libxcb-render-util
        libxcb-util
        libxcb-wm
        fontconfig
        freetype
        libsm
        libxext
        libxrender
        libice
        libxkbcommon
        libX11
    ];
    direnv = {
      enable = true;
      enableZshIntegration = true;
    };
    # Make x11 over ssh work
    ssh.setXAuthLocation = true;
  };

  # Custom package overrides
  nixpkgs.config = {
    permittedInsecurePackages = [];
    allowBroken = true;
  };
}
