{ lib, stdenvNoCC, python3, gtk4, gobject-introspection, wrapGAppsHook4, makeWrapper, makeDesktopItem }:

let
  python = python3.withPackages (p: [ p.pygobject3 ]);
  desktop = makeDesktopItem {
    name = "stealth-keyboard";
    desktopName = "Stealth Keyboard";
    comment = "Per-key colors, keypress fades, and timed keyboard effects";
    exec = "stealth-keyboard";
    icon = "input-keyboard";
    categories = [ "Settings" "HardwareSettings" ];
  };
in stdenvNoCC.mkDerivation {
  pname = "stealth-keyboard";
  version = "0.3.0";
  src = ./.;
  nativeBuildInputs = [ gobject-introspection wrapGAppsHook4 makeWrapper ];
  buildInputs = [ gtk4 ];
  dontBuild = true;
  doCheck = true;
  checkPhase = ''
    ${python}/bin/python -m unittest discover -s tests -v
  '';
  installPhase = ''
    mkdir -p $out/bin $out/share/stealth-keyboard
    cp app.py keyboard.py layout.py effects.py profiles.py controller.py $out/share/stealth-keyboard/
    makeWrapper ${python}/bin/python $out/bin/stealth-keyboard \
      --add-flags $out/share/stealth-keyboard/app.py
    cp -r ${desktop}/share/applications $out/share/
  '';
  meta = {
    description = "Per-key RGB and effect controls for the MSI Stealth 14 Studio keyboard";
    mainProgram = "stealth-keyboard";
    platforms = lib.platforms.linux;
  };
}
