# Vendored fonts

`awesome-cv.cls` prefers the **variable** build of Source Sans 3 so the body
weight can be set on the `wght` axis (see the "BODY-WEIGHT KNOB" comment in the
class). The Debian/TeX Live font packages only ship discrete static weights, so
we vendor the variable font here to keep builds deterministic and tunable.

Expected files (referenced by `awesome-cv.cls`):

- `SourceSans3VF-Roman.otf`
- `SourceSans3VF-Italic.otf`

If these are absent, the class falls back to the static "Source Sans 3" package,
then to "Source Sans Pro", so the build still works (just without axis tuning).

## How to (re)fetch

From the repo root:

```sh
# 1. Fetch and unpack the variable fonts. Note: in this archive the upright is
#    named "…-Upright.otf"; we vendor it as "…-Roman.otf" (the name the class uses).
curl -L -o /tmp/ss3vf.zip \
  https://github.com/adobe-fonts/source-sans/releases/download/3.052R/VF-source-sans-3.052R.zip
rm -rf /tmp/ss3vf && unzip -q -o /tmp/ss3vf.zip -d /tmp/ss3vf
cp /tmp/ss3vf/VF/SourceSans3VF-Upright.otf fonts/SourceSans3VF-Roman.otf
cp /tmp/ss3vf/VF/SourceSans3VF-Italic.otf  fonts/SourceSans3VF-Italic.otf

# 2. The OFL license is NOT in the VF zip; fetch it from the repo (via the API,
#    which avoids the asset CDN). OFL requires it to ship alongside the fonts.
curl -sL -H "Accept: application/vnd.github.raw" \
  https://api.github.com/repos/adobe-fonts/source-sans/contents/LICENSE.md \
  -o fonts/LICENSE-SourceSans3.txt

ls -l fonts/*.otf fonts/LICENSE-SourceSans3.txt
```

Then `git add fonts/*.otf fonts/LICENSE-SourceSans3.txt`.

## License

Source Sans 3 is licensed under the SIL Open Font License 1.1 (OFL-1.1), which
permits bundling/redistribution. Source: https://github.com/adobe-fonts/source-sans
