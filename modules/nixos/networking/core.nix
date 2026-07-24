{ config, pkgs, ... }:

{
  # gpsd
  services.gpsd = {
    enable = true;
    devices = [ "/dev/rfcomm0" ];
  };

  services.blueman.enable = true;


  # Networking configuration
  networking = {
    hostName = "Sam-Computer";

    # Enable networking via NetworkManager
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };

    usePredictableInterfaceNames = true;

    # Firewall configuration
    #nftables breaks qemu maybe
    nftables.enable = true;
    search = [ ];

    firewall = {
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
        ip saddr 169.254.0.0/16 accept
      '';
    };
  };

  # Kernel modules for networking
  boot = {
    blacklistedKernelModules = [ "cdc_ncm" ];
    kernelModules = [ "tcp_bbr" "ax88179_178a" "r8152" ];

    # TCP BBR congestion control
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };
}
