{ config, pkgs, ... }:

{
  # Hardware-specific kernel modules and parameters
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.msi-ec ];
    # msi-ec is loaded after boot via systemd — loading it here hung the boot stage.
    blacklistedKernelModules = [ "msi-ec" ];
    kernelModules = [ "i2c-dev" "ec_sys" ];

    # Kernel parameters for embedded controller and memory compression
    kernelParams = [
      "ec_sys.write_support=1"  # For MControlCenter (embedded controller)
      "lru_gen.enabled=y"       # Enable Multi-Gen LRU
      "zswap.enabled=1"
      "zswap.shrinker_enabled=1"
      "zswap.compressor=zstd"
      "zswap.max_pool_percent=40"
      "zswap.zpool=zsmalloc"
    ];
  };

  # Load msi-ec after multi-user.target so a slow/failing probe cannot hang early boot.
  systemd.services.msi-ec = {
    description = "Load MSI EC kernel module";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.kmod}/bin/modprobe msi-ec";
    };
  };
}
