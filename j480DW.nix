{ lib, stdenv, fetchurl, cups, dpkg, ghostscript, a2ps, coreutils, gnused, gawk, file, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "mfcj480dwlpr";
  version = "1.0.0-0";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf102093/mfcj480dwlpr-${version}.i386.deb";
    sha256 = "9dee186bebc49fe9ef70c0abf0f2a529a7b76cdaa552d76d7a674e034710ed48";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ cups ghostscript dpkg a2ps ];

  dontUnpack = true;

  installPhase = ''
    dpkg-deb -x $src $out

    substituteInPlace $out/opt/brother/Printers/mfcj480dw/lpd/filtermfcj480dw \
    --replace /opt "$out/opt" \

    sed -i '/GHOST_SCRIPT=/c\GHOST_SCRIPT=gs' $out/opt/brother/Printers/mfcj480dw/lpd/psconvertij2

    patchelf --set-interpreter ${stdenv.cc.libc}/lib/ld-linux.so.2 $out/opt/brother/Printers/mfcj480dw/lpd/brmfcj480dwfilter

    mkdir -p $out/lib/cups/filter/
    ln -s $out/opt/brother/Printers/mfcj480dw/lpd/filtermfcj480dw $out/lib/cups/filter/brother_lpdwrapper_mfcj480dw

    wrapProgram $out/opt/brother/Printers/mfcj480dw/lpd/psconvertij2 \
    --prefix PATH ":" ${ lib.makeBinPath [ gnused coreutils gawk ] }

    wrapProgram $out/opt/brother/Printers/mfcj480dw/lpd/filtermfcj480dw \
    --prefix PATH ":" ${ lib.makeBinPath [ ghostscript a2ps file gnused coreutils ] }
    '';

  meta = {
    homepage = "http://www.brother.com/";
    description = "Brother MFC-J480DW LPR driver";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
    downloadPage = "http://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=mfcj480dw_us_eu_as&os=128";
    maintainers = [ lib.maintainers.yochai ];
  };
}
