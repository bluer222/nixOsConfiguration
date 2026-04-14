{ config, pkgs, ... }:
{
  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.cups-dymo ];
  #descover printers
  services.avahi = {
  enable = true;
  nssmdns4 = true;
  openFirewall = true;
  };
}
