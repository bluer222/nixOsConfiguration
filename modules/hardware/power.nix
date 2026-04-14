{ config, pkgs, ... }:
{
  #powermanagement
  powerManagement.enable = true;
  #conflics with tlp
  services.power-profiles-daemon.enable = false;
  #enable tlp with config
  services.tlp = {
    enable = true;
    settings = {
      TLP_ENABLE = 1;
      TLP_DEFAULT_MODE = "BAT";
      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 1;
      NMI_WATCHDOG = 0;
      MEM_SLEEP_ON_AC = "deep";
      MEM_SLEEP_ON_BAT = "deep";
      DISK_DEVICES = "nvme0n1 sda";
      DISK_APM_LEVEL_ON_AC = "keep";
      DISK_APM_LEVEL_ON_BAT = "keep";
      DISK_IOSCHED = "mq-deadline mq-deadline";
      SATA_LINKPWR_ON_AC = "max_performance med_power_with_dipm";
      SATA_LINKPWR_ON_BAT = "min_power med_power_with_dipm";
      AHCI_RUNTIME_PM_ON_AC = "on";
      AHCI_RUNTIME_PM_ON_BAT = "auto";
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "off";
      WOL_DISABLE = "Y";
      SOUND_POWER_SAVE_ON_AC = 1;
      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_DRIVER_DENYLIST = "nouveau nvidia";
      USB_EXCLUDE_PHONE = 1;
    };
  };
}
