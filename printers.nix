{ config, pkgs, ... }:

let
mfcj480dwlpr = pkgs.callPackage ./j480DW.nix { };
mfcj480dw-cupswrapper = pkgs.callPackage ./j480DW-wrapper.nix { };
in
{
  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ /*mfcj480dwlpr pkgs.mfcj470dwlpr*/ pkgs.mfcj470dw-cupswrapper mfcj480dw-cupswrapper pkgs.cups-dymo];
  #descover printers
  services.avahi = {
  enable = true;
  nssmdns4 = true;
  openFirewall = true;
  };
}
