{ config, pkgs, ... }:
{
  # Avahi for service discovery (mDNS)
  services.avahi = {
    enable = true;
    openFirewall = true;
    nssmdns4 = true;
    nssmdns6 = true;
    nssmdnsFull = true;
  };
}
