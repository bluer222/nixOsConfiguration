{ pkgs, llm-agents, ... }:
let
  agents = llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  t3 = agents.t3code.override {
    providerPackages = [ agents.codex agents.claude-code ];
  };
in {
  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.initrd.availableKernelModules = [
    "xhci_pci" "ehci_pci" "ahci" "nvme" "usb_storage" "uas" "sd_mod"
    "virtio_pci" "virtio_blk" "virtio_scsi"
  ];
  boot.growPartition = true;
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
  };

  networking.hostName = "t3-mini";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  hardware.enableRedistributableFirmware = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = { enable = true; addresses = true; };
  };
  time.timeZone = "America/New_York";

  # The host must keep working after the laptop disconnects.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };
  services.logind.settings.Login = {
    IdleAction = "ignore";
    HandleLidSwitch = "ignore";
  };
  zramSwap.enable = true;

  users.users.samm = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = import ./ssh-keys.nix;
  };
  # Key-only administration, as on a cloud image. No shared image password.
  security.sudo.wheelNeedsPassword = false;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    t3 agents.codex agents.claude-code
    git curl jq ripgrep tmux nano nodejs python3 gcc gnumake pkg-config unzip
  ];
  environment.variables.SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";

  systemd.services.t3code = {
    description = "T3 Code host";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ "/run/current-system/sw" "/run/wrappers" ];
    environment = {
      HOME = "/home/samm";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      NIX_LD = "/run/current-system/sw/share/nix-ld/lib/ld.so";
      NIX_LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
    };
    serviceConfig = {
      User = "samm";
      WorkingDirectory = "/home/samm";
      ExecStart = "${t3}/bin/t3 serve --host 127.0.0.1 --port 3773";
      Restart = "always";
      RestartSec = 5;
      KillMode = "mixed";
      UMask = "0077";
    };
  };

  assertions = [ {
    assertion = (import ./ssh-keys.nix) != [ ];
    message = "Add your laptop's SSH public key to hosts/t3-mini/ssh-keys.nix.";
  } ];
}
