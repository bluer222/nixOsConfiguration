{ config, pkgs, inputs, ... }:

{
  # KDE Plasma desktop environment and kde-specific packages
  environment.systemPackages = with pkgs; [
    kdePackages.filelight
    kdePackages.kmail
    kdePackages.kmailtransport
    kdePackages.kmail-account-wizard
    kdePackages.keysmith
    kdePackages.ghostwriter
    kdePackages.kate
    kdePackages.baloo
    kdePackages.oxygen-sounds
    kdePackages.kde-gtk-config
    kdePackages.karousel
    kdePackages.spectacle
    kdePackages.kitemmodels
    #(pkgs.kdePackages.spectacle.override {
    #    tesseractLanguages = [ "eng" ];
    #})
  ];

  programs.kde-pim.kmail = true;
  programs.partition-manager.enable = true;
}
