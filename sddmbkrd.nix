{ pkgs, lib, stdenv, themeConfig ? null }:
stdenv.mkDerivation rec {
  pname = "sddm-astronaut";
  version = "1.0";

  src = pkgs.fetchFromGitHub {
    owner = "Keyitdev";
    repo = "sddm-astronaut-theme";
    rev = "48ea0a792711ac0c58cc74f7a03e2e7ba3dc2ac0";
    hash = "sha256-kXovz813BS+Mtbk6+nNNdnluwp/7V2e3KJLuIfiWRD0=";
  };

    fetch = pkgs.fetchurl {
    url = "https://invent.kde.org/plasma/plasma-workspace-wallpapers/-/raw/master/Altai/contents/images/5120x2880.png?ref_type=heads&inline=false";
    sha256 = "sha256-Q0J6SMtDVWplulg7PryYz8iUGcg3I2NVQ/9MlzxIjto="; # Replace with actual hash (see next step)
  };

  dontWrapQtApps = true;
  propagatedBuildInputs = with pkgs.kdePackages; [ qt5compat qtsvg ];

  installPhase =
    let
      iniFormat = pkgs.formats.ini { };
      configFile = iniFormat.generate "" { General = themeConfig; };

      basePath = "$out/share/sddm/themes/sddm-astronaut-theme";
    in
    ''
      mkdir -p ${basePath}
      cp -r $src/* ${basePath}
      rm ${basePath}/background.png
    cp ${fetch.out} ${basePath}/background.png
    '' + lib.optionalString (themeConfig != null) ''
      ln -sf ${configFile} ${basePath}/theme.conf.user
    '';
  meta = {
    description = "Modern looking qt6 sddm theme";
    homepage = "https://github.com/${src.owner}/${pname}";
    license = lib.licenses.gpl3;

    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ danid3v ];
  };
}
