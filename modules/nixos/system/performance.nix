{ config, pkgs, ... }:

{
  # Prioritize desktop responsiveness
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    # Ensure KWin and Plasma are prioritized
    extraRules = [
      { name = "kwin_wayland"; type = "Realtime"; }
      { name = "kwin_x11"; type = "Realtime"; }
      { name = "plasmashell"; type = "Realtime"; }
      { name = "Xorg"; type = "Realtime"; }
    ];
  };

  # Prioritize foreground processes
  services.system76-scheduler.enable = true;

  # Distribute interrupts across CPU cores
  services.irqbalance.enable = true;

  # Resource management for active user sessions (custom module)
  services.uresourced.enable = true;

  # Optimize for gaming
  programs.gamemode.enable = true;

  # Use dbus-broker for better responsiveness
  services.dbus.implementation = "broker";

  # Kernel tweaks for responsiveness
  boot.kernel.sysctl = {
    # Proactively reclaim memory to avoid stalls
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    
    # Improve multitasking under heavy load
    "kernel.sched_child_runs_first" = 0;
    "kernel.sched_autogroup_enabled" = 1;
    "kernel.sched_cfs_bandwidth_slice_us" = 3000;

    # Better disk throughput/latency for SSDs
    "vm.dirty_bytes" = 268435456;
    "vm.dirty_background_bytes" = 134217728;
    "vm.page-cluster" = 0; # Better for ZRAM/ZSWAP
  };
}
