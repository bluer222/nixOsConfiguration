{ config, inputs, pkgs, lib, stdenv, ... }:

{
  #some packages need to be system
  environment = {
    systemPackages = [ 
      pkgs.mcontrolcenter
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
    '';
  };

  programs = {
    gamescope.enable = true;
    #add nix-ld for dynamic executables
    nix-ld.enable = true;
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
