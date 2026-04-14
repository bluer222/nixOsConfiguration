{ config, pkgs, ... }:

{
  # Security and networking tools
  environment.systemPackages = with pkgs; [
    burpsuite
    tor-browser
    nmap
    metasploit
    rustscan
    wireshark
  ];

  programs.wireshark.enable = true;
}
