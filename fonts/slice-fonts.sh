#!/usr/bin/env sh
# Slice the four static Source Sans 3 weights awesome-cv.cls loads (Body, BodyItalic,
# Bold, BoldItalic) out of the variable font. See README.md for why static instances
# are needed. Run from the repo root (needs fonttools):
#
#   [BODY_WGHT=380] [BOLD_WGHT=700] [VF_DIR=path] [OUT=fonts] sh fonts/slice-fonts.sh
#
# If VF_DIR is unset, the variable font is fetched into a temp dir.
set -eu

BODY_WGHT="${BODY_WGHT:-380}"
BOLD_WGHT="${BOLD_WGHT:-700}"
OUT="${OUT:-$(dirname "$0")}"
VF_DIR="${VF_DIR:-}"

if [ -z "$VF_DIR" ]; then
  TMP="$(mktemp -d)"
  echo "Fetching Source Sans 3 variable font..."
  curl -Lso "$TMP/vf.zip" \
    https://github.com/adobe-fonts/source-sans/releases/download/3.052R/VF-source-sans-3.052R.zip
  unzip -qo "$TMP/vf.zip" -d "$TMP"
  VF_DIR="$TMP/VF"
fi

BODY_WGHT="$BODY_WGHT" BOLD_WGHT="$BOLD_WGHT" VF_DIR="$VF_DIR" OUT="$OUT" python3 - <<'PY'
import os
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

vf, out = os.environ["VF_DIR"], os.environ["OUT"]
body, bold = int(os.environ["BODY_WGHT"]), int(os.environ["BOLD_WGHT"])

def make(src, wght, dst):
    f = TTFont(os.path.join(vf, src))
    instantiateVariableFont(f, {"wght": wght}, inplace=True)
    f.save(os.path.join(out, dst))
    print(f"  {dst:<28} wght={wght}")

print("Slicing static instances:")
make("SourceSans3VF-Upright.ttf", body, "SourceSans3-Body.ttf")
make("SourceSans3VF-Italic.ttf",  body, "SourceSans3-BodyItalic.ttf")
make("SourceSans3VF-Upright.ttf", bold, "SourceSans3-Bold.ttf")
make("SourceSans3VF-Italic.ttf",  bold, "SourceSans3-BoldItalic.ttf")
print("Done.")
PY
echo "Wrote SourceSans3-{Body,BodyItalic,Bold,BoldItalic}.ttf to $OUT"
