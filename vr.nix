{ config, inputs, pkgs, lib, ... }:
{
imports = [
    inputs.home-manager.nixosModules.home-manager
];

#hardware.graphics.extraPackages = [pkgs.monado-vulkan-layers];

  #fixes conflict or somthing
  #environment.etc."xdg/openxr/1/active_runtime.json".source = lib.mkForce "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";
  #environment.etc."xdg/openxr/1/active_runtime.json".source = lib.mkForce "${pkgs.monado}/share/openxr/1/openxr_monado.json";

#services.monado = {
#  enable = true;
#  #wivrn is the defualt runtime not this
#  #defaultRuntime = true; # Register as default OpenXR runtime
#};

#systemd.user.services.monado.environment = {
#  STEAMVR_LH_ENABLE = "1";
#  XRT_COMPOSITOR_COMPUTE = "1";
 # WMR_HANDTRACKING = "0";
#};
#required for had tracking or somthing
programs.git = {
  enable = true;
  lfs.enable = true;
};


 # home.sessionVariables = {
 #   # Force applications to use OpenComposite instead of SteamVR
 #   VR_OVERRIDE = "${pkgs.opencomposite}/lib/opencomposite";
 # XDG_CACHE_HOME  = "@{HOME}/.cache";
 # XDG_CONFIG_HOME = "@{HOME}/.config";
 # XDG_DATA_HOME   = "@{HOME}/.local/share";
 # XDG_STATE_HOME  = "@{HOME}/.local/state";
 #   # Optional: Set OpenXR runtime to WiVRn if needed
 #   # XR_RUNTIME_JSON = "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";
 # };
 # };

services.wivrn = {
  enable = true;
  openFirewall = true;
  # Write information to /etc/xdg/openxr/1/active_runtime.json, VR applications
  # will automatically read this and work with WiVRn (Note: This does not currently
  # apply for games run in Valve's Proton)
    defaultRuntime = true;

  # Run WiVRn as a systemd service on startup
  autoStart = false;
   package = pkgs.wivrn.override {
      cudaSupport = true;
    };

  # Config for WiVRn (https://github.com/WiVRn/WiVRn/blob/master/docs/configuration.md)
  config = {
    enable = true;
    json = {
      # 1.0x foveation scaling
      scale = 1.0;
      # 100 Mb/s
      bitrate = 100000000;
      encoders = [
        {
          encoder = "nvenc";
          codec = "av1";
          # 1.0 x 1.0 scaling
          width = 1.0;
          height = 1.0;
          offset_x = 0.0;
          offset_y = 0.0;
        }
      ];
    };
  };
};
}