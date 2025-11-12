{ config, inputs, pkgs, lib, stdenv, ... }:

{
#boot stuff actually related to booting
  boot = {
  resumeDevice = "/dev/disk/by-uuid/68fe3efa-3a25-452a-aa77-3c0882d19d93";
    #splashscreen
    plymouth = {
      enable = true;


    };
        #quiet grub and ec sys for MControlCenter
    kernelParams = [
      "quiet"
      "loglevel=3"
      "udev.log_level=3"
      "ec_sys.write_support=1"
      "zswap.enabled=1"          #rather than swapping out ram, try to compress it
      "zswap.shrinker_enabled=1" # if the page is unused for long enough, move it to disk swap
      "zswap.compressor=zstd"    # You can also try lzo-rle (faster, less compression)
      "zswap.max_pool_percent=50"  # default = 20% of RAM, can tweak
      "zswap.zpool=zsmalloc"     # default, usually best
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
