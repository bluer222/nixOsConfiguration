{ config, pkgs, ... }:

{
  # Hardware-specific kernel modules and parameters
  boot = {
    extraModulePackages = [
      (config.boot.kernelPackages.msi-ec.overrideAttrs (oldAttrs: rec {
        src = pkgs.fetchFromGitHub {
          owner = "bluer222";
          repo = "msi-ec";
          rev = "main";
          sha256 = "sha256-ECWLV3Yd8ISJtHoKOfo5esWoHUKwKyGCrjQEAIkjleM=";
        };
      }))
    ];
    blacklistedKernelModules = [ "cdc_ncm" ];
    
    kernelModules = [ "i2c-dev" "msi-ec" ];
    # TCP BBR congestion control
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };

    # Kernel parameters for embedded controller and memory compression
    kernelParams = [
      "lru_gen.enabled=y"       # Enable Multi-Gen LRU
      "zswap.enabled=1"
      "zswap.shrinker_enabled=1"
      "zswap.compressor=zstd"
      "zswap.max_pool_percent=40"
      "zswap.zpool=zsmalloc"
    ];
  };
}
