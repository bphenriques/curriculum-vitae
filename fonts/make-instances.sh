#!/usr/bin/env sh
# Regenerate the static Source Sans 3 weight instances used by awesome-cv.cls.
#
# Why static instances instead of the variable font directly: xdvipdfmx (xelatex's
# PDF backend) collapses every use of one variable-font file to a single instance,
# so body/regular/bold sharing one VF all render at the same weight (bold breaks).
# Slicing separate static files per weight sidesteps that.
#
# Why we also rename small-cap glyphs: the variable font names its small caps
# "I.s", "S.s", ... (capital base + ".s"), which xdvipdfmx mis-maps in the PDF text
# layer (e.g. "Engineer" extracts with a dotless-i/long-s and won't match in ATS).
# We rename them to the lowercase-base ".sc" convention Adobe's static OTFs use
# ("i.sc", "s.sc", ...), which extracts cleanly. Verify after building by pasting
# the PDF into a plain editor and searching "Engineer".
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

def rename_smallcaps(font):
    # "I.s" (capital base + .s) -> "i.sc" (lowercase base + .sc) so xdvipdfmx
    # writes correct ToUnicode for the small-caps headings.
    rename = {}
    for g in font.getGlyphOrder():
        if g.endswith(".s"):
            base = g[:-2]
            if base and base.isalpha() and base.isupper():
                rename[g] = base.lower() + ".sc"
    if not rename:
        return 0
    font.setGlyphOrder([rename.get(g, g) for g in font.getGlyphOrder()])
    if "glyf" in font:
        glyf = font["glyf"]
        glyf.glyphs = {rename.get(k, k): v for k, v in glyf.glyphs.items()}
        # composite glyphs (e.g. accented small caps) reference bases by name
        for g in glyf.glyphs.values():
            if g.isComposite():
                for comp in g.components:
                    comp.glyphName = rename.get(comp.glyphName, comp.glyphName)
    for tag in ("hmtx", "vmtx"):
        if tag in font:
            font[tag].metrics = {rename.get(k, k): v for k, v in font[tag].metrics.items()}
    if "cmap" in font:
        for st in font["cmap"].tables:
            st.cmap = {c: rename.get(g, g) for c, g in st.cmap.items()}
    seen = set()
    def walk(o):
        if id(o) in seen:
            return
        seen.add(id(o))
        if isinstance(o, list):
            for i, v in enumerate(o):
                if isinstance(v, str):
                    o[i] = rename.get(v, v)
                else:
                    walk(v)
        elif isinstance(o, dict):
            ni = {}
            for k, v in o.items():
                nk = rename.get(k, k) if isinstance(k, str) else k
                if isinstance(v, str):
                    nv = rename.get(v, v)
                else:
                    walk(v); nv = v
                ni[nk] = nv
            o.clear(); o.update(ni)
        elif hasattr(o, "__dict__"):
            for k, v in vars(o).items():
                if isinstance(v, str):
                    setattr(o, k, rename.get(v, v))
                else:
                    walk(v)
    for tag in ("GSUB", "GPOS", "GDEF"):
        if tag in font and getattr(font[tag], "table", None) is not None:
            walk(font[tag].table)
    return len(rename)

def make(src, wght, dst):
    f = TTFont(os.path.join(vf_dir, src))
    instantiateVariableFont(f, {"wght": wght}, inplace=True)
    n = rename_smallcaps(f)
    f.save(os.path.join(out, dst))
    print("  %-28s wght=%d, renamed %d small-cap glyphs" % (dst, wght, n))

print("Slicing static instances + fixing small-cap names:")
make("SourceSans3VF-Upright.ttf", body, "SourceSans3-Body.ttf")
make("SourceSans3VF-Italic.ttf",  body, "SourceSans3-BodyItalic.ttf")
make("SourceSans3VF-Upright.ttf", bold, "SourceSans3-Bold.ttf")
make("SourceSans3VF-Italic.ttf",  bold, "SourceSans3-BoldItalic.ttf")
print("Done.")
PY
echo "Wrote SourceSans3-{Body,BodyItalic,Bold,BoldItalic}.ttf to $OUT"
