{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kdePackages.kwallet
    kdePackages.kwallet-pam
  ];
}
