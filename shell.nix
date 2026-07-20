{ pkgs }:
let
  cv = import ./nix { inherit pkgs; };
in
pkgs.mkShellNoCC {
  name = "curriculum-vitae";
  meta.description = "Dev shell to build the CV (xelatex), re-slice fonts, and regen the QR code";

  packages = [
    cv.tex # xelatex + latexmk + packages
    cv.pythonEnv # python3 + fonttools (manual font work)
    pkgs.qrencode
    cv.build-cv
    cv.build-coverletter
    cv.regen-qrcode
    cv.regen-fonts
  ];

  # So a bare `latexmk`/`xelatex` in the shell finds Roboto too (the commands set
  # this themselves; this covers manual invocations).
  FONTCONFIG_FILE = cv.fontsConf;

  shellHook = ''
    echo "curriculum-vitae — commands:"
    echo "  build-cv            build cv.pdf"
    echo "  build-coverletter   build coverletter.pdf"
    echo "  regen-qrcode [url]  regenerate content/qrcode.png (default: easter-egg URL)"
    echo "  regen-fonts         re-slice fonts/SourceSans3-*.ttf (e.g. BODY_WGHT=370 regen-fonts)"
  '';
}
