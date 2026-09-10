{
  lib,
  buildGoModule,
  makeWrapper,
  libnotify,
  pipewire,
  pulseaudio, # pactl subscribe (pipewire-pulse)
  tesseract,
  wl-clipboard,
  bluez,
  upower,
  niri,
  wireplumber,
  coreutils,
  noctalia,
  brightnessctl,
  kdePackages,
  systemd,
}:

buildGoModule {
  pname = "niri-helper";
  version = "0.1.0";
  src = ./.;
  vendorHash = null;

  nativeBuildInputs = [ makeWrapper ];

  ldflags = [
    "-s"
    "-w"
  ];

  postInstall = ''
    wrapProgram $out/bin/niri-helper \
      --prefix PATH : ${lib.makeBinPath [
        libnotify
        pipewire
        pulseaudio
        tesseract
        wl-clipboard
        bluez
        upower
        niri
        wireplumber
        coreutils
        noctalia
        brightnessctl
        systemd
      ]} \
      --set NIRI_HELPER_OXYGEN ${kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo
  '';

  meta = {
    description = "Session helper daemon for niri; CLI forwards commands over a unix socket";
    mainProgram = "niri-helper";
  };
}
