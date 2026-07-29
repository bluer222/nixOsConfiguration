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
    kdePackages.kitemmodels

    # Core archive manager
    kdePackages.ark

    # Command-line tools required for extracting/compressing
    p7zip        # For .7z and complex formats
    unzip        # For .zip files
    zip          # To allow zipping via Dolphin
    unrar        # For .rar files
    gnutar       # For .tar files
    gzip         # For .tar.gz files
  ];

  programs.kde-pim.kmail = true;
  programs.partition-manager.enable = true;
  programs.kdeconnect.enable = true;
}
