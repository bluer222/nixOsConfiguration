{ config, inputs, pkgs, ... }:
{
  # Keep the prompt on the kernel/NVIDIA suspend console, preserving upstream paths.
  imports = [
    (builtins.toFile "secure-suspend.nix" (
      builtins.replaceStrings
        [ "-ws -c8" "./" ]
        [ "-wfs -c63" "${inputs.secure-suspend}/" ]
        (builtins.readFile "${inputs.secure-suspend}/secure-suspend.nix")
    ))
  ];
  security.secureSuspend.enable = true;

  # Save VRAM before secure-suspend locks the disk.
  hardware.nvidia.powerManagement.kernelSuspendNotifier = false;
  # NVIDIA 615 defaults this on unless the module parameter is explicitly disabled.
  hardware.nvidia.moduleParams.nvidia.NVreg_UseKernelSuspendNotifiers = 0;

  # Power management core
  # powertop tunables removed: conflict with TLP (double-apply runtime PM and
  # re-enable devices TLP denylists, e.g. nvidia)
  powerManagement.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "suspend";
  };

  # Thermal management for Intel CPUs
  services.thermald.enable = true;

  # Power profiles daemon conflicts with TLP
  services.power-profiles-daemon.enable = false;

  services.upower.enable = true;

  # Enable TLP with the Profile Daemon (tlp-pd)
  services.tlp = {
    enable = true;
    pd.enable = true;

    settings = {
      # Basic Operation
      TLP_ENABLE = 1;

      #this means to auto switch unless the user sets a profile manually
      TLP_AUTO_SWITCH = 2;

      TLP_PROFILE_AC="BAL";
      TLP_PROFILE_BAT="SAV";


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

      # Avoid balance_power, which caused severe write slowdowns on this laptop.
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "performance";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "balance_performance";

      # Hardware HWP Dynamic Boost: Allows quicker frequency ramp-up
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;
      CPU_HWP_DYN_BOOST_ON_SAV = 0;

      # Turbo Boost: Keep ON even in power saving so bursty tasks finish fast and cores return to deep C-states (C8/C10)
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      CPU_BOOST_ON_SAV = 1;

      # Minimum/Maximum performance percentages
      # Avoid heavy downclocking caps which prolong uncore/DRAM active state and prevent package C-states
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 100;
      CPU_MAX_PERF_ON_SAV = 80;

      # Platform profile (firmware) — only SAV is forced low-power
      PLATFORM_PROFILE_ON_SAV = "low-power";

      # ========================================================================
      # Graphics (iGPU)
      # ========================================================================
      # Leave frequency limits to the driver. TLP requires valid MHz values;
      # zero is outside this GPU's supported range.

      # ========================================================================
      # Networking & Radio
      # ========================================================================
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      WIFI_PWR_ON_SAV = "on"; # power-save only; WiFi stays enabled
      WOL_DISABLE = "Y";

      # ========================================================================
      # PCIe & Runtime PM
      # ========================================================================
      # PCIe Active State Power Management
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "powersave";
      PCIE_ASPM_ON_SAV = "powersupersave";

      # Runtime Power Management for devices
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_ON_SAV = "auto";
      # TLP's default driver denylist already includes nvidia and nouveau.

      # USB autosuspend — SAV only via defaults; keep global gentle
      # (TLP has no USB_AUTOSUSPEND_ON_SAV; leave unset so AC/BAT unchanged)

      # AHCI link power — SAV only
      SATA_LINKPWR_ON_SAV = "min_power";

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
