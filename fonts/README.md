# Vendored fonts

`awesome-cv.cls` uses **static weight instances** sliced out of the Source Sans 3
variable font. Files it references:

- `SourceSans3-Body.ttf` — body copy (currently wght **380**; the summary, bullets,
  dates, and skill pills)
- `SourceSans3-BodyItalic.ttf` — italic/slanted body
- `SourceSans3-Bold.ttf` — bold (wght **700**)
- `SourceSans3-BoldItalic.ttf` — bold italic

If these are absent, the class falls back to the static "Source Sans 3" package,
then to "Source Sans Pro", so the build still works.

## Why static instances (and not the variable font directly)

Two backend limitations forced this:

1. **CFF2 not embeddable.** The `.otf` variable font is CFF2-flavored, and
   `xdvipdfmx` (xelatex's PDF backend) can't embed it — it fails with
   `PS OpenType but no "CFF " table.. Maybe variable font? (not supported)`.
2. **One instance per VF file.** Even with the `.ttf` (glyf) variable font,
   xdvipdfmx collapses *every* use of a single VF file to one instance. So body
   (380), regular (400), and bold (700) all sharing one VF render at the **same**
   weight — the page looks uniformly thin and bold silently disappears.

Slicing a **separate static file per weight** sidesteps both: each embeds cleanly,
and bold is a genuinely different file, so `\textbf` works.

## Small-caps / ATS text extraction

Small-caps headings (roles, the tagline, the degree line) would otherwise extract
from the PDF as garbled glyphs (a dotless-i / long-s) and fail ATS keyword matching.
That's fixed in `cv.tex` with `\XeTeXgenerateactualtext=1`, which records the typed
characters — so it needs no glyph-level changes to these fonts.

## Retuning the body weight

Edit the weight and re-slice (needs `fonttools` — `pip install fonttools`):

```sh
BODY_WGHT=370 sh fonts/make-instances.sh   # 350 = airy, 400 = Regular
```

Then rebuild. `make-instances.sh` fetches the variable font automatically if it
isn't already unpacked (pass `VF_DIR=/path/to/VF` to reuse a local copy).

## License

Source Sans 3 is licensed under the SIL Open Font License 1.1 (OFL-1.1), which
permits bundling/redistribution (see `LICENSE-SourceSans3.txt`).
Source: https://github.com/adobe-fonts/source-sans
