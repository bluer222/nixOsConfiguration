# Hand-maintained after the ext4 → LUKS+LVM+btrfs migration.
# Do not run nixos-generate-config over this file.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = true;

  # LVM-on-LUKS. systemd stage 1 unlocks this, then discovers vg0 automatically
  # (boot.initrd.services.lvm.enable defaults on with systemd initrd).
  boot.initrd.luks.devices."cryptlvm" = {
    device = "/dev/disk/by-partlabel/cryptroot";
    allowDiscards = true;
  };

  boot.kernelModules = [ "kvm-intel" "nvidia_uvm" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=@" "compress=zstd:1" "noatime" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-label/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=@home" "compress=zstd:1" "noatime" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-label/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=@nix" "compress-force=zstd:1" "noatime" ];
    };

  fileSystems."/var/log" =
    { device = "/dev/disk/by-label/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=@log" "compress=zstd:1" "noatime" ];
      neededForBoot = true;
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/BOOT-EFI";
      fsType = "vfat";
      options = [ "umask=0077" "noatime" ];
    };

  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "2G";

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  swapDevices = [ { device = "/dev/disk/by-label/nixos-swap"; priority = -1; } ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
