{ config, pkgs, inputs, ... }:

{
  # KDE Plasma desktop environment and kde-specific packages
  environment.systemPackages = with pkgs; [
    kdePackages.filelight
    kdePackages.kmail
    kdePackages.kmailtransport
    kdePackages.kmail-account-wizard
    kdePackages.keysmith
    kde-rounded-corners.overrideAttrs (oldAttrs: {
      src = pkgs.fetchFromGitHub {
        owner = "matinlotfali";
        repo = "KDE-Rounded-Corners";
        rev = "2cf9329b31b3152e5513f7069c4bb11c765fdc6e";
        sha256 = "sha256-mVoLCnpWHC2qDouO97n2cmxiewLCokjnWl1I9tnkIN4=";
      };
    })
  ];

  programs.kde-pim.kmail = true;
  programs.partition-manager.enable = true;
}
