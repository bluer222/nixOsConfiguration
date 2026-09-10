{ config, inputs, pkgs, lib, stdenv, ... }:

{
  #boot stuff actually related to booting
  boot = {
    #splashscreen
    plymouth = {
      enable = true;
      #theme = "bgrt";
      theme = "nix-flake";
      themePackages = [
        (pkgs.callPackage inputs.plymouth-luks-subtle {})
      ];
    };
    # Bootloader and console verbosity
    kernelParams = [
      "quiet"
      "loglevel=3"
      "udev.log_level=3"
      "preempt=full"
    ];
    consoleLogLevel = 3;
    # https://github.com/NixOS/nixpkgs/pull/108294
    initrd.verbose = false;
    # Bootloader.
    loader = {
      #i dont want to wait
      timeout = 1;
      #efi stuff to make grub work
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot"; # ← use the same mount point here.
      };
      grub = {
        enable = true;
        #hide it(esc to show it)
        timeoutStyle = "hidden";
        #no ugily nixos spash(this jpg is just the bgrt image)
        splashImage = ../../hosts/samm-desktop/boot.jpg;
        useOSProber = true;
        device = "nodev";
        efiSupport = true;
      };
    };
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
