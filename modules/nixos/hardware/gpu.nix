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
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia-container-toolkit.enable = true;
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

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
#vulkan beta was the only one that worked for me in the past
    #switching to beta because its newer(560{open is the default now})
    package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;
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
}
