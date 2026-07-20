#!/usr/bin/env sh
# Regenerate the static Source Sans 3 weight instances used by awesome-cv.cls.
#
# Why static instances instead of the variable font directly: xdvipdfmx (xelatex's
# PDF backend) collapses every use of one variable-font file to a single instance,
# so body/regular/bold sharing one VF all render at the same weight (bold breaks).
# Slicing separate static files per weight sidesteps that.
#
# Note on ATS / copy-paste: small-caps text extracting correctly is handled in
# cv.tex via \XeTeXgenerateactualtext=1 (it records the typed characters), so the
# fonts need no glyph-name surgery here.
#
# Usage (from repo root):
#   BODY_WGHT=380 BOLD_WGHT=700 sh fonts/make-instances.sh
#
# Requires: fonttools (pip install fonttools) and the Source Sans 3 variable TTFs.
# If the VF isn't already at $VF_DIR, this fetches it into a temp dir.
set -eu

BODY_WGHT="${BODY_WGHT:-380}"
BOLD_WGHT="${BOLD_WGHT:-700}"
OUT="${OUT:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)}"
PYTHON="${PYTHON:-python3}"
VF_DIR="${VF_DIR:-}"

if [ -z "$VF_DIR" ]; then
  TMP="$(mktemp -d)"
  echo "Fetching Source Sans 3 variable font..."
  curl -L -o "$TMP/ss3vf.zip" \
    https://github.com/adobe-fonts/source-sans/releases/download/3.052R/VF-source-sans-3.052R.zip
  unzip -q -o "$TMP/ss3vf.zip" -d "$TMP"
  VF_DIR="$TMP/VF"
fi

BODY_WGHT="$BODY_WGHT" BOLD_WGHT="$BOLD_WGHT" VF_DIR="$VF_DIR" OUT="$OUT" "$PYTHON" - <<'PY'
import os
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

vf_dir = os.environ["VF_DIR"]; out = os.environ["OUT"]
body = int(os.environ["BODY_WGHT"]); bold = int(os.environ["BOLD_WGHT"])

def make(src, wght, dst):
    f = TTFont(os.path.join(vf_dir, src))
    instantiateVariableFont(f, {"wght": wght}, inplace=True)
    f.save(os.path.join(out, dst))
    print("  %-28s wght=%d" % (dst, wght))

print("Slicing static instances:")
make("SourceSans3VF-Upright.ttf", body, "SourceSans3-Body.ttf")
make("SourceSans3VF-Italic.ttf",  body, "SourceSans3-BodyItalic.ttf")
make("SourceSans3VF-Upright.ttf", bold, "SourceSans3-Bold.ttf")
make("SourceSans3VF-Italic.ttf",  bold, "SourceSans3-BoldItalic.ttf")
print("Done.")
PY
echo "Wrote SourceSans3-{Body,BodyItalic,Bold,BoldItalic}.ttf to $OUT"
