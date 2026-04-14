{ config, inputs, pkgs, lib, stdenv, ... }:

let
  #ovveride version to 0.5.0
  mcontrolcenter = pkgs.mcontrolcenter.overrideAttrs (oldAttrs: rec {
    version = "0.5.0";
    src = pkgs.fetchFromGitHub {
      owner = "dmitry-s93";
      repo = "MControlCenter";
      rev = version;
      hash = "sha256-Gl+YnbUbwtwF2WHT39bIKh48qSIMe3fpzxgdvifR4DQ=";
    };
  });
in
{
  #some packages need to be system
  environment.systemPackages = [ 
    mcontrolcenter
  ];

  services.flatpak.enable = true;
  programs.gamescope.enable = true;
  #add nix-ld for dynamic executables
  programs.nix-ld.enable = true;

  #firmware updates with discover
  services.fwupd.enable = true;

  programs.direnv.enable = true;
  programs.direnv.enableZshIntegration = true;

  #use igpu by default
  environment.variables = {
    __GLX_VENDOR_LIBRARY_NAME = "mesa";  # Avoids loading NVIDIA GLX
    LIBVA_DRIVER_NAME = "iHD";           # Use Intel VAAPI
    VDPAU_DRIVER = "va_gl";              # Use VAAPI for VDPAU
  };

  # Udev rules for hardware
  services.udev.extraRules = ''
    # ZED Camera
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", MODE="0666"
    KERNEL=="video*", ATTRS{idVendor}=="2b03", MODE="0666"
  '';

  # Custom package overrides
  nixpkgs.config.permittedInsecurePackages = [];
  nixpkgs.config.allowBroken = true;

  # Make x11 over ssh work
  programs.ssh.setXAuthLocation = true;
}
