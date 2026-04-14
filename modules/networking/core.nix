{ config, pkgs, ... }:

{
  # Networking configuration
  networking.hostName = "Sam-Computer";

  # Enable networking via NetworkManager
  networking.networkmanager.enable = true;

  # Kernel modules for networking
  boot.blacklistedKernelModules = [ "cdc_ncm" ];
  boot.kernelModules = [ "tcp_bbr" "ax88179_178a" ];

  boot.extraModprobeConfig = ''
    softdep cdc_ncm pre: ax88179_178a
  '';

  networking.usePredictableInterfaceNames = true;

  # TCP BBR congestion control
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # Firewall configuration
  networking.nftables.enable = true;
  networking.nameservers = [
    "1.1.1.2"
    "1.0.0.2"
  ];
  networking.search = [ ];
  networking.networkmanager.dns = "none";

  networking.firewall = {
    enable = true;

    # Allow traffic from Waydroid
    extraForwardRules = ''
      iifname "waydroid0" oifname != "waydroid0" udp dport 53 accept comment "Waydroid DNS UDP"
      iifname "waydroid0" oifname != "waydroid0" tcp dport 53 accept comment "Waydroid DNS TCP"
    '';

    # Allow replies to come back (return traffic)
    extraInputRules = ''
      oifname "waydroid0" iifname != "waydroid0" udp sport 53 accept comment "Waydroid DNS UDP return"
      oifname "waydroid0" iifname != "waydroid0" tcp sport 53 accept comment "Waydroid DNS TCP return"
    '';
  };
}
