{ config, inputs, pkgs, lib, stdenv, ... }:

{
  #boot stuff actually related to booting
  boot = {
    resumeDevice = "/dev/disk/by-uuid/68fe3efa-3a25-452a-aa77-3c0882d19d93";
    #splashscreen
    plymouth = {
      enable = true;
    };
    # Bootloader and console verbosity
    kernelParams = [
      "quiet"
      "loglevel=3"
      "udev.log_level=3"
    ];
    consoleLogLevel = 3;
    # https://github.com/NixOS/nixpkgs/pull/108294
    initrd.verbose = false;
    # Bootloader.
    loader = {
      #i dont want to wait
      timeout = 1;
      grub = {
        #hide it(esc to show it)
        #timeoutStyle = "menu";
        timeoutStyle = "hidden";
        #no ugily nixos spash
        splashImage = "/home/samm/boot.jpg";
        #splashImage = null;
      };
      #efi stuff to make grub work
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot"; # ← use the same mount point here.
      };
      #enable grub
      grub = {
        enable = true;
        useOSProber = true;
        device = "nodev";
        efiSupport = true;
      };
    };
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
