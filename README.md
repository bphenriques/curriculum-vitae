[![Build](https://github.com/bphenriques/curriculum-vitae/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/bphenriques/curriculum-vitae/actions/workflows/build.yml)
[![CV Latest Version](https://img.shields.io/badge/Download-Latest-green)](https://github.com/bphenriques/curriculum-vitae/releases/latest/download/bruno-henriques-cv.pdf)

# Curriculum Vitae

Based on [posquit0/Awesome-CV](https://github.com/posquit0/Awesome-CV) template. Made some personal changes to support cloud-based tags.

## Development

A Nix flake provides the full toolchain (xelatex, fonts, fonttools, qrencode). With
[direnv](https://direnv.net/) + [nix-direnv](https://github.com/nix-community/nix-direnv),
`direnv allow` drops you into the shell; otherwise run `nix develop`. Then:

| Command | What it does |
| --- | --- |
| `build-cv` | Build `cv.pdf` |
| `build-coverletter` | Build `coverletter.pdf` |
| `regen-qrcode [url]` | Regenerate `content/qrcode.png` (defaults to the easter-egg URL) |
| `regen-fonts` | Re-slice `fonts/SourceSans3-*.ttf` from the variable font (see `fonts/README.md`) |

Each is also a flake app, e.g. `nix run .#cv` or `nix run .#qrcode -- https://example.com`.
