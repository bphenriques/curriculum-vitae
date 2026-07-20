[![Build](https://github.com/bphenriques/curriculum-vitae/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/bphenriques/curriculum-vitae/actions/workflows/build.yml)
[![CV Latest Version](https://img.shields.io/badge/Download-Latest-green)](https://github.com/bphenriques/curriculum-vitae/releases/latest/download/bruno-henriques-cv.pdf)

## Development

```sh
nix build .#cv   # -> result/bruno-henriques-cv.pdf
```

Alternatively, run `nix develop` or use `direnv allow` and then:
- `build-cv`: Build `cv.pdf`
- `build-coverletter`: Build `coverletter.pdf`
- `regen-fonts`: Re-slice `fonts/SourceSans3-*.ttf` from the variable font (see `fonts/README.md`)

## CI/CD

Every push to `master` builds and publishes the latest version.

## Acknowledges

Based on [posquit0/Awesome-CV](https://github.com/posquit0/Awesome-CV), with personal tweaks.