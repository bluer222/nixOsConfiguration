{ config, pkgs, ... }:
{
  # Power management core
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # Thermal management for Intel CPUs
  services.thermald.enable = true;

  # Power profiles daemon
  services.power-profiles-daemon.enable = true;

  # TLP is disabled in favor of PPD
  services.tlp.enable = false;
}
