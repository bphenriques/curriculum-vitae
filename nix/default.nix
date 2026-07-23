{ pkgs }:
let
  inherit (pkgs) lib;

  # TeX Live medium + the extras awesome-cv.cls pulls in.
  tex = pkgs.texliveMedium.withPackages (ps: [
    ps.collection-latexextra # tcolorbox, enumitem, eso-pic, environ, ...
    ps.collection-pictures # pgf/tikz (tcolorbox dependency)
    ps.fontawesome6
    ps.tikzfill # tcolorbox 'skins' dependency
    ps.sourcesanspro # "Source Sans Pro" fallback face
  ]);

  # fonttools, for re-slicing the variable font (regen-fonts).
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.fonttools ]);

  # Roboto (header font) discoverable via fontconfig; source-sans is the class's fallback.
  fontsConf = pkgs.makeFontsConf {
    fontDirectories = [
      pkgs.roboto
      pkgs.source-sans
    ];
  };

  qrUrl = "https://bphenriques.com";
  genQr = ''qrencode -o content/qrcode.png -s 12 -m 2 -l M --foreground=000000FF --background=FFFFFF00 "${qrUrl}"'';

  latexmkCmd = "latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode";

  # Hermetic build (`nix build .#cv`): clean sandbox snapshot, what CI/releases consume.
  mkPdf = { name, texFile, qr ? false, }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit name;
      src = lib.cleanSource ../.;
      nativeBuildInputs = [ tex ] ++ lib.optional qr pkgs.qrencode;
      FONTCONFIG_FILE = fontsConf;
      buildPhase = ''
        export HOME="$TMPDIR" # latexmk/xelatex need a writable HOME
        ${lib.optionalString qr genQr}
        ${latexmkCmd} ${texFile}
      '';
      installPhase = ''install -Dm644 ${lib.removeSuffix ".tex" texFile}.pdf "$out/${name}.pdf"'';
    };

  # Fast local build: latexmk in the working tree (PDF lands next to the .tex).
  mkBuild = { name, texFile, qr ? false, }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ tex ] ++ lib.optional qr pkgs.qrencode;
      text = ''
        export FONTCONFIG_FILE=${fontsConf}
        test -f ${texFile} || { echo "Run from the repo root (${texFile} not found)." >&2; exit 1; }
        ${lib.optionalString qr genQr}
        exec ${latexmkCmd} ${texFile}
      '';
    };

  build-cv = mkBuild {
    name = "build-cv";
    texFile = "cv.tex";
    qr = true;
  };

  build-coverletter = mkBuild {
    name = "build-coverletter";
    texFile = "coverletter.tex";
  };

  # Re-slice fonts/SourceSans3-*.ttf; honors BODY_WGHT/BOLD_WGHT (see fonts/README.md).
  regen-fonts = pkgs.writeShellApplication {
    name = "regen-fonts";
    runtimeInputs = [
      pythonEnv
      pkgs.curl
      pkgs.unzip
      pkgs.coreutils
    ];
    text = ''
      test -d fonts || { echo "Run from the repo root (fonts/ not found)." >&2; exit 1; }
      export OUT="$PWD/fonts"
      exec ${pkgs.bash}/bin/bash ${../fonts/slice-fonts.sh} "$@"
    '';
  };
in
{
  cv = mkPdf {
    name = "bruno-henriques-cv";
    texFile = "cv.tex";
    qr = true;
  };

  coverletter = mkPdf {
    name = "bruno-henriques-coverletter";
    texFile = "coverletter.tex";
  };

  devShell = pkgs.mkShellNoCC {
    name = "curriculum-vitae";
    meta.description = "Dev shell to build the CV (xelatex) and re-slice fonts";
    packages = [
      tex
      pythonEnv
      build-cv
      build-coverletter
      regen-fonts
    ];
    FONTCONFIG_FILE = fontsConf; # so bare latexmk/xelatex finds Roboto for manual runs
    shellHook = ''
      echo "curriculum-vitae — commands:"
      echo "  build-cv            build cv.pdf"
      echo "  build-coverletter   build coverletter.pdf"
      echo "  regen-fonts         re-slice fonts/SourceSans3-*.ttf (e.g. BODY_WGHT=370 regen-fonts)"
    '';
  };
}
