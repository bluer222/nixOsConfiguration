{ config, pkgs, ... }:

{
  # Hardware-specific kernel modules and parameters
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.msi-ec ];
    blacklistedKernelModules = [ "cdc_ncm" ];
    
    kernelModules = [ "i2c-dev" "ec_sys" "msi-ec" ];
    # TCP BBR congestion control
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };

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
}
