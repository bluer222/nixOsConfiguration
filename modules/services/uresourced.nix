{ config, lib, pkgs, ... }:

let
  cfg = config.services.uresourced;
  
  uresourced = pkgs.stdenv.mkDerivation rec {
    pname = "uresourced";
    version = "0.5.4";

    src = pkgs.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "benzea";
      repo = "uresourced";
      rev = "v${version}";
      sha256 = "0snznjisgvqd1gccynsnnh6ww5mq0ncl7pl70hykc01d9xid0d2r";
    };

    nativeBuildInputs = with pkgs; [
      meson
      ninja
      pkg-config
    ];

    buildInputs = with pkgs; [
      glib
      systemd
      pipewire # Search indicated this is a dependency
    ];

    # meson.build likely tries to install to /usr/lib/systemd/system
    # We need to tell it where to put things or let Nix handle it
    mesonFlags = [
      "-Dsystemdsystemunitdir=${placeholder "out"}/lib/systemd/system"
    ];

    meta = with lib; {
      description = "A daemon to dynamically allocate resources to the active user";
      homepage = "https://gitlab.freedesktop.org/benzea/uresourced";
      license = licenses.lgpl21Plus;
      platforms = platforms.linux;
    };
  };
in
{
  options.services.uresourced = {
    enable = lib.mkEnableOption "uresourced daemon";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.uresourced = {
      description = "uresourced daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "dbus.service" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.UResourced";
        ExecStart = "${uresourced}/libexec/uresourced";
        Restart = "always";
      };
    };

    # The daemon installs its DBus policy to share/dbus-1/system.d/
    # Adding the package here ensures DBus picks it up.
    services.dbus.packages = [ uresourced ];
  };
}
