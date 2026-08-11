{
  lib,
  buildGoModule,
  makeWrapper,
  libnotify,
  pipewire,
  grim,
  slurp,
  tesseract,
  wl-clipboard,
  bluez,
  upower,
  avizo,
  niri,
  swaybg,
  pulseaudio,
  coreutils,
  albert,
  kdePackages,
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
        grim
        slurp
        tesseract
        wl-clipboard
        bluez
        upower
        avizo
        niri
        swaybg
        pulseaudio
        coreutils
        albert
      ]} \
      --set NIRI_HELPER_OXYGEN ${kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo \
      --set NIRI_HELPER_KWALLET_INIT ${kdePackages.kwallet-pam}/libexec/pam_kwallet_init
  '';

  meta = {
    description = "Session helper daemon for niri; CLI forwards commands over a unix socket";
    mainProgram = "niri-helper";
  };
}
