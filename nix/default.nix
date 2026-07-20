# Shared build environment + commands for the CV, consumed by both ./shell.nix
# (dev shell) and ../flake.nix (apps). Keeping it here means the toolchain and the
# helper commands are defined once.
{ pkgs }:
let
  # LaTeX toolchain. Generous-but-curated so `xelatex` has every package the class
  # pulls in (tcolorbox+skins, tikz/tikzfill, fontawesome6, eso-pic, enumitem, ...).
  # If a future edit needs a package that's missing, either add it by name here or
  # swap the whole set for `pkgs.texliveFull` (heavier, but guaranteed complete).
  tex = pkgs.texlive.combine {
    inherit (pkgs.texlive)
      scheme-medium
      collection-xetex # xetex, fontspec, unicode-math
      collection-latexextra # tcolorbox, enumitem, eso-pic, environ, ...
      collection-pictures # pgf/tikz (tcolorbox dependency)
      collection-fontsrecommended
      latexmk
      fontawesome6
      tikzfill # tcolorbox 'skins' dependency
      sourcesanspro # "Source Sans Pro" fallback face
      ;
  };

  # Python with fonttools, for slicing the variable font into static weights.
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.fonttools ]);

  # Make the header font (Roboto) discoverable by fontconfig/XeTeX. The body fonts
  # are vendored under fonts/ and loaded by path, so they don't need to be here;
  # source-sans is included only for the class's fallback branch.
  fontsConf = pkgs.makeFontsConf {
    fontDirectories = [
      pkgs.roboto
      pkgs.source-sans
    ];
  };

  # Easter-egg QR target (a static site self-hosted in a homelab microVM).
  qrUrl = "https://cv-vm.chameleon-goby.ts.net/";

  # Hermetic PDF build (`nix build .#cv`). Unlike the `build-*` commands below --
  # which run latexmk in the working tree for fast local iteration -- this builds
  # in the sandbox from a clean source snapshot, so it's what CI/releases consume.
  mkPdf =
    { name, texFile }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit name;
      src = pkgs.lib.cleanSource ../.;
      nativeBuildInputs = [ tex ];
      FONTCONFIG_FILE = fontsConf;
      buildPhase = ''
        runHook preBuild
        export HOME="$TMPDIR"   # latexmk/xelatex need a writable HOME for caches
        latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode ${texFile}
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        install -Dm644 ${pkgs.lib.removeSuffix ".tex" texFile}.pdf "$out/${name}.pdf"
        runHook postInstall
      '';
    };

  cv = mkPdf {
    name = "bruno-henriques-cv";
    texFile = "cv.tex";
  };
  coverletter = mkPdf {
    name = "bruno-henriques-coverletter";
    texFile = "coverletter.tex";
  };

  build-cv = pkgs.writeShellApplication {
    name = "build-cv";
    runtimeInputs = [ tex ];
    text = ''
      export FONTCONFIG_FILE=${fontsConf}
      test -f cv.tex || { echo "Run from the repo root (cv.tex not found)." >&2; exit 1; }
      exec latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode cv.tex
    '';
  };

  build-coverletter = pkgs.writeShellApplication {
    name = "build-coverletter";
    runtimeInputs = [ tex ];
    text = ''
      export FONTCONFIG_FILE=${fontsConf}
      test -f coverletter.tex || { echo "Run from the repo root (coverletter.tex not found)." >&2; exit 1; }
      exec latexmk -xelatex -file-line-error -halt-on-error -interaction=nonstopmode coverletter.tex
    '';
  };

  # Regenerate the QR image. Pass a URL to override the default easter-egg target.
  regen-qrcode = pkgs.writeShellApplication {
    name = "regen-qrcode";
    runtimeInputs = [ pkgs.qrencode ];
    text = ''
      url="''${1:-${qrUrl}}"
      test -d content || { echo "Run from the repo root (content/ not found)." >&2; exit 1; }
      qrencode -o content/qrcode.png -s 12 -m 2 -l M \
        --foreground=000000FF --background=FFFFFF00 "$url"
      echo "Wrote content/qrcode.png -> $url"
    '';
  };

  # Re-slice fonts/SourceSans3-*.ttf from the variable font. Honors the script's
  # env knobs, e.g. `regen-fonts` or `BODY_WGHT=370 regen-fonts`. Writes into $PWD/fonts.
  regen-fonts = pkgs.writeShellApplication {
    name = "regen-fonts";
    runtimeInputs = [
      pythonEnv
      pkgs.curl
      pkgs.unzip
      pkgs.coreutils
      pkgs.bash
    ];
    text = ''
      test -d fonts || { echo "Run from the repo root (fonts/ not found)." >&2; exit 1; }
      export OUT="$PWD/fonts"
      exec bash ${../fonts/make-instances.sh} "$@"
    '';
  };
in
{
  inherit
    tex
    pythonEnv
    fontsConf
    cv
    coverletter
    build-cv
    build-coverletter
    regen-qrcode
    regen-fonts
    ;
}
