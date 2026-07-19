#!/usr/bin/env sh
# Regenerate the static Source Sans 3 weight instances used by awesome-cv.cls.
#
# Why static instances instead of the variable font directly: xdvipdfmx (xelatex's
# PDF backend) collapses every use of one variable-font file to a single instance,
# so body/regular/bold sharing one VF all render at the same weight (bold breaks).
# Slicing separate static files per weight sidesteps that.
#
# Usage (from repo root):
#   BODY_WGHT=380 BOLD_WGHT=700 sh fonts/make-instances.sh
#
# Requires: fonttools (pip install fonttools) and the Source Sans 3 variable TTFs.
# If the VF isn't already at $VF_DIR, this fetches it into a temp dir.
set -eu

BODY_WGHT="${BODY_WGHT:-380}"
BOLD_WGHT="${BOLD_WGHT:-700}"
OUT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
VF_DIR="${VF_DIR:-}"

if [ -z "$VF_DIR" ]; then
  VF_DIR="$(mktemp -d)/VF"
  echo "Fetching Source Sans 3 variable font..."
  curl -L -o "$VF_DIR/../ss3vf.zip" \
    https://github.com/adobe-fonts/source-sans/releases/download/3.052R/VF-source-sans-3.052R.zip
  unzip -q -o "$VF_DIR/../ss3vf.zip" -d "$VF_DIR/.."
fi

echo "Slicing body=$BODY_WGHT bold=$BOLD_WGHT from $VF_DIR ..."
fonttools varLib.instancer -q "$VF_DIR/SourceSans3VF-Upright.ttf" "wght=$BODY_WGHT" -o "$OUT/SourceSans3-Body.ttf"
fonttools varLib.instancer -q "$VF_DIR/SourceSans3VF-Italic.ttf"  "wght=$BODY_WGHT" -o "$OUT/SourceSans3-BodyItalic.ttf"
fonttools varLib.instancer -q "$VF_DIR/SourceSans3VF-Upright.ttf" "wght=$BOLD_WGHT" -o "$OUT/SourceSans3-Bold.ttf"
fonttools varLib.instancer -q "$VF_DIR/SourceSans3VF-Italic.ttf"  "wght=$BOLD_WGHT" -o "$OUT/SourceSans3-BoldItalic.ttf"
echo "Done. Wrote SourceSans3-{Body,BodyItalic,Bold,BoldItalic}.ttf to $OUT"
