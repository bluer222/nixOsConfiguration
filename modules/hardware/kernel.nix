{ config, pkgs, ... }:

{
  # Hardware-specific kernel modules and parameters
  boot.extraModulePackages = [ config.boot.kernelPackages.msi-ec ];
  boot.kernelModules = [ "i2c-dev" "ec_sys" "msi-ec" ];

  # Kernel parameters for embedded controller and memory compression
  boot.kernelParams = [
    "ec_sys.write_support=1"  # For MControlCenter (embedded controller)
    "zswap.enabled=1"
    "zswap.shrinker_enabled=1"
    "zswap.compressor=zstd"
    "zswap.max_pool_percent=50"
    "zswap.zpool=zsmalloc"
  ];
}
