{ config, pkgs, ... }:
{
  # Power management core
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # Thermal management for Intel CPUs
  services.thermald.enable = true;

  # Power profiles daemon conflicts with TLP
  services.power-profiles-daemon.enable = false;

  # Enable TLP with the Profile Daemon (tlp-pd)
  services.tlp = {
    enable = true;
    pd.enable = true;

    settings = {
      # Basic Operation
      TLP_ENABLE = 1;
      TLP_DEFAULT_MODE = "AC";
      TLP_PERSISTENT_DEFAULT = 0;

      # ========================================================================
      # CPU Scaling & Performance (Intel Raptor Lake i7-13620H)
      # ========================================================================
      # Use the 'active' mode which is best for 12th/13th Gen Hybrid architecture
      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";

      # Governor: 'powersave' is the correct partner for 'active' mode EPP
      # It ramps up when needed, no need to set anything else
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_GOVERNOR_ON_SAV = "powersave";

      # Energy Performance Preference (EPP): This is the primary driver for Raptor Lake efficiency
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance"; # Better responsiveness/efficiency than balance_power
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";

      # Hardware HWP Dynamic Boost: Allows quicker frequency ramp-up
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;
      CPU_HWP_DYN_BOOST_ON_SAV = 0;

      # Turbo Boost: On 13th Gen, it's usually better to keep this ON even on battery
      # but use EPP to control the behavior. We only disable it for 'Power Saver'.
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      CPU_BOOST_ON_SAV = 0;

      # Minimum/Maximum performance percentages
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 80; # Cap P-cores slightly on battery to avoid heat
      CPU_MAX_PERF_ON_SAV = 50; # Aggressive cap for power saving

      # ========================================================================
      # Graphics (iGPU)
      # ========================================================================
      #100 is the minimum
      INTEL_GPU_MIN_FREQ_ON_AC = 100;
      INTEL_GPU_MIN_FREQ_ON_BAT = 100;
      INTEL_GPU_MIN_FREQ_ON_SAV = 100;

      INTEL_GPU_MAX_FREQ_ON_AC = 0; # 0 means unlimited in this case
      INTEL_GPU_MAX_FREQ_ON_BAT = 1000; # Cap iGPU to 1GHz on battery
      INTEL_GPU_MAX_FREQ_ON_SAV = 600;

      # ========================================================================
      # Networking & Radio
      # ========================================================================
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      WIFI_PWR_ON_SAV = "on";
      WOL_DISABLE = "Y";

      # ========================================================================
      # PCIe & Runtime PM
      # ========================================================================
      # PCIe Active State Power Management
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "balance_power";
      PCIE_ASPM_ON_SAV = "powersupersave";

      # Runtime Power Management for devices
      RUNTIME_PM_ON_AC = "on";   # 'on' means PM is disabled (safer for AC)
      RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_ON_SAV = "auto";
      # Exclude Nvidia as it handles its own PM via the driver
      RUNTIME_PM_DENYLIST = "nvidia nouveau";

      # ========================================================================
      # Suspend & Sleep
      # ========================================================================
      # Force S3 (Suspend to RAM) instead of s2idle (Modern Standby)
      MEM_SLEEP_ON_AC = "deep";
      MEM_SLEEP_ON_BAT = "deep";
      MEM_SLEEP_ON_SAV = "deep";

      # ========================================================================
      # Disk & Audio
      # ========================================================================
      DISK_DEVICES = "nvme0n1";
      #APM disabled because only applies to hdd
      DISK_APM_LEVEL_ON_AC = "255 255";
      DISK_APM_LEVEL_ON_BAT = "255 255";
      DISK_APM_LEVEL_ON_SAV = "255 255";

      SOUND_POWER_SAVE_ON_AC = 1;
      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";
    };
  };
}
