{ config, pkgs, fetchurl, lib, inputs, ... }:

let
  inherit (lib) mkAfter;
in

{
  #video accell
  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver =
      pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  };
  # Enable OpenGL for amd and nvidia
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      #it says this in the intel graphics page
      vpl-gpu-rt # or intel-media-sdk for QSV
      #video accell
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libvdpau-va-gl
    ];

  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  }; # Force intel-media-driver

  # Load nvidia
  services.xserver.videoDrivers = [ "nvidia" "vmware" ];
  hardware.nvidia-container-toolkit.enable = true;
  # CDI generation does slow GPU introspection; don't let it gate
  # multi-user.target — docker only needs it when a container actually starts.
  systemd.services.nvidia-container-toolkit-cdi-generator.wantedBy =
    lib.mkForce [ "graphical.target" ];
  #use cuda
  #nixpkgs.config.cudaSupport = true;
  # Load nvidia driver for Xorg and Wayland
  hardware.nvidia = {
    #midigates bottlenecks by transferig power from cpu to gpu when needed
    dynamicBoost.enable = true;
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = true;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = true;
    # Kernel notifiers cover a single suspend/hibernate. suspend-then-hibernate
    # resumes from S3 and immediately hibernates; that path hangs in
    # PM_HIBERNATION_PREPARE unless userspace writes to
    # /proc/driver/nvidia/suspend first (NVIDIA's system-sleep hook). NixOS
    # skips nvidia-suspend.service and that hook when this is true.
    powerManagement.kernelSuspendNotifier = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Do not disable this unless your GPU is unsupported or if you have a good reason to.
    #NOW THE DEFAULT IN 560 YAY
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # vulkan_beta (595.44.09) does not build against linuxPackages_latest (7.2).
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  # See ../../gpu.md for rationale + undo instructions.
  #
  # nvidia.nix eagerly adds nvidia_uvm to boot.kernelModules for open-module
  # users because the softdep lazy-load is broken upstream (NixOS#334180).
  # systemd-modules-load then runs modprobe during sysinit.target, which pulls
  # in the whole nvidia driver synchronously — RM init stalls ~2s on failing
  # MSI SBIOS ACPI calls (NBCI platform requests) and blocked ~45% of boot.
  # Filter it out of the sync path and load it after graphical.target instead;
  # the udev mknod rules still fire whenever the module appears.
  environment.etc."modules-load.d/nixos.conf" = lib.mkForce {
    text = lib.concatStringsSep "\n"
      (lib.filter (m: m != "nvidia_uvm") config.boot.kernelModules) + "\n";
    mode = "0644";
  };

  systemd.services.load-nvidia-uvm = {
    description = "Load nvidia_uvm off the boot-critical path";
    wantedBy = [ "graphical.target" ];
    after = [ "graphical.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kmod}/bin/modprobe nvidia_uvm";
      RemainAfterExit = true;
    };
  };

  services.udev.extraRules = ''
    KERNEL=="card*", KERNELS=="0000:00:02.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/intel-igpu"
    KERNEL=="card*", KERNELS=="0000:01:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/nvidia-dgpu", ENV{ID_VGA_SWITCHEROO}="1"
  '';

  hardware.nvidia.prime = {
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };
    # Make sure to use the correct Bus ID values for your system!
    intelBusId = "PCI:0@0:2:0";
    nvidiaBusId = "PCI:1@0:0:0";
  };

  # nvidia-suspend.service is only RequiredBy systemd-suspend.service, so it
  # never runs during suspend-then-hibernate. systemd-sleep invokes this hook
  # around each inner action (SYSTEMD_SLEEP_ACTION=suspend then hibernate).
  environment.etc."systemd/system-sleep/nvidia-s2h".source =
    pkgs.writeShellScript "nvidia-s2h" ''
      set -eu
      [ -e /proc/driver/nvidia/suspend ] || exit 0
      [ "''${2-}" = suspend-then-hibernate ] || exit 0
      case "''${1-}:''${SYSTEMD_SLEEP_ACTION-}" in
        pre:suspend)
          echo suspend > /proc/driver/nvidia/suspend
          ;;
        pre:hibernate)
          echo hibernate > /proc/driver/nvidia/suspend
          ;;
        pre:suspend-after-failed-hibernate)
          echo suspend > /proc/driver/nvidia/suspend
          ;;
        post:*)
          echo resume > /proc/driver/nvidia/suspend
          ;;
      esac
    '';

  # Same race as LACT: powerd talks to the GPU across the RTC wake.
  systemd.services.nvidia-powerd = {
    conflicts = [ "sleep.target" ];
    before = [ "sleep.target" ];
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
  };
}
