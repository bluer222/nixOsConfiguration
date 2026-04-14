{ config, pkgs, ... }:
{
  # Avahi for service discovery (mDNS)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
