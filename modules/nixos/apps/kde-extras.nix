{ config, pkgs, inputs, ... }:

{
  # KDE Plasma desktop environment and kde-specific packages
  environment.systemPackages = with pkgs; [
    kdePackages.filelight
    keepassxc    # replaces Keysmith (TOTP); Secret Service API can replace KWallet
    thunderbird  # replaces Kmail/Akonadi
    kdePackages.ghostwriter
    kdePackages.kate
    kdePackages.oxygen-sounds
    kdePackages.kde-gtk-config

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

  programs.partition-manager.enable = true;
  programs.kdeconnect.enable = true;
}
