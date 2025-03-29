{ lib, stdenv, fetchurl, pkgs, makeWrapper, bash }:

stdenv.mkDerivation rec {
  pname = "mfcj480dw-cupswrapper";
  version = "1.0.0-0";
mfcj480dwlpr = pkgs.callPackage ./j480DW.nix { };
  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf102095/mfcj480dw_cupswrapper_GPL_source_${version}.tar.gz";
    sha256 = "e1a717a91f0d78a846abd68db054107712b80a2711fc7b769f91151b166a5086";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    bash # shebang
  ];

  makeFlags = [ "-C" "brcupsconfig" "all" ];

  postPatch = ''
    WRAPPER=cupswrapper/cupswrappermfcj480dw

    substituteInPlace $WRAPPER \
      --replace-fail /opt "${mfcj480dwlpr}/opt" \
      --replace-fail /usr "${mfcj480dwlpr}/usr" \
      --replace-fail /etc "$out/etc"

    substituteInPlace $WRAPPER \
      --replace-fail "cp " "cp -p "
  '';

  installPhase = ''
    runHook preInstall

    TARGETFOLDER=$out/opt/brother/Printers/mfcj480dw/cupswrapper/
    PPDFOLDER=$out/share/cups/model/
    FILTERFOLDER=$out/lib/cups/filter/

    mkdir -p $TARGETFOLDER
    mkdir -p $PPDFOLDER
    mkdir -p $FILTERFOLDER

    cp brcupsconfig/brcupsconfpt1 $TARGETFOLDER
    cp cupswrapper/cupswrappermfcj480dw $TARGETFOLDER
    cp PPD/brother_mfcj480dw_printer_en.ppd $PPDFOLDER

    ln -s ${mfcj480dwlpr}/lib/cups/filter/brother_lpdwrapper_mfcj480dw $FILTERFOLDER/

    runHook postInstall
  '';

  meta = {
    homepage = "http://www.brother.com/";
    description = "Brother MFC-J480DW CUPS wrapper driver";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux;
    downloadPage = "http://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=mfcj480dw_us_eu_as&os=128";
    maintainers = [ lib.maintainers.yochai ];
  };
}

