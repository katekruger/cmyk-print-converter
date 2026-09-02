# CMYK Print Converter

**A Claude Code plugin that turns RGB images into print-ready CMYK — from chat.**

[![CI](https://github.com/katekruger/cmyk-print-converter/actions/workflows/ci.yml/badge.svg)](https://github.com/katekruger/cmyk-print-converter/actions/workflows/ci.yml)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Requires](https://img.shields.io/badge/requires-ImageMagick-orange.svg)
![Version](https://img.shields.io/badge/version-0.1.1-green.svg)

Drop an image into chat, say *"convert this to CMYK for print,"* and get back a file your
print vendor can actually use — converted through a real ICC color profile, with that profile
**embedded** so the press reads your colors correctly.

Works as a Claude Code plugin **or** as a standalone shell script.

## What it does

- Converts JPEG / TIFF / PNG / BMP / GIF / WebP from RGB → CMYK through a real ICC profile
- Default target: **US Web Coated (SWOP)**, the North American print standard
- **Embeds** the profile in the output so print vendors read colors correctly
- Respects an existing embedded profile; assumes sRGB only when there isn't one
- Routes formats that cannot hold CMYK to TIFF, and says why
- **Skips** vector and RAW files with a stated reason instead of producing garbage
- Batches folders, optionally recursing

**Honest limits.** RGB→CMYK is lossy — out-of-gamut colors shift, and that is physics, not a
bug. Without the SWOP profile installed you get macOS Generic CMYK and a loud warning. This is
a raster tool: vector and prepress work needs a different pipeline. See
[Limitations](#limitations).

## Requirements

| | |
|---|---|
| **OS** | macOS — the profile fallbacks read macOS ColorSync paths |
| **ImageMagick** | `brew install imagemagick` — required |
| **SWOP profile** | *Optional.* Without it: Generic CMYK plus a warning. [Install guide →](skills/convert-to-cmyk/references/swop-profile.md) |

## Install

**As a Claude Code plugin, via the marketplace:**

```
/plugin marketplace add katekruger/cmyk-print-converter
/plugin install cmyk-print-converter
```

**Locally, from a clone:**

```bash
git clone https://github.com/katekruger/cmyk-print-converter.git
cd cmyk-print-converter
claude plugin install .
```

**From the packaged bundle** — this repo ships both the packaged plugin and the source it was
built from. Download `cmyk-print-converter.plugin` from the repo root or from
[Releases](https://github.com/katekruger/cmyk-print-converter/releases) and open it:

```bash
curl -L -O https://raw.githubusercontent.com/katekruger/cmyk-print-converter/main/cmyk-print-converter.plugin
```

The bundle and the source are kept in lockstep by CI, which rebuilds the bundle on every push
and fails if it differs from the committed one.

## Quick start

```bash
brew install imagemagick
bash scripts/rgb2cmyk.sh logo.png -o print-ready
ls print-ready/          # -> logo.tif  (CMYK, profile embedded)
```

Verify it really is CMYK:

```bash
magick identify -format '%[colorspace] %[profile:icc]\n' print-ready/logo.tif
# CMYK Generic CMYK Profile
```

## What's inside

```
.claude-plugin/     manifest + self-marketplace
skills/             the convert-to-cmyk skill and its references
scripts/            rgb2cmyk.sh (the converter), build, and version helpers
cmyk-print-converter.plugin   the packaged bundle (committed; CI keeps it in sync)
profiles/           drop your own .icc here (gitignored)
tests/              43-assertion suite
docs/               architecture, configuration, development
```

## Skills

| Skill | Triggers on | What it does |
|-------|-------------|--------------|
| `convert-to-cmyk` | "convert to CMYK", "make this print-ready", "prepare for print", "change the color profile for the printer", or an uploaded image plus a print question | Checks for ImageMagick, runs the converter, reports what converted and what was skipped, and flags honestly when the profile was the generic fallback rather than true SWOP |

## Command reference

```bash
bash scripts/rgb2cmyk.sh ~/assets -o ~/print-ready         # a whole folder
bash scripts/rgb2cmyk.sh logo.jpg banner.png               # individual files
bash scripts/rgb2cmyk.sh ~/assets -r                       # recurse subfolders
bash scripts/rgb2cmyk.sh ~/assets -p /path/to/profile.icc  # force a profile
bash scripts/rgb2cmyk.sh photo.jpg -q 100                  # max JPEG quality
```

| Flag | Argument | Default | Effect |
|------|----------|---------|--------|
| `-o`, `--out` | `DIR` | `./cmyk-out` | Output directory, created if missing |
| `-p`, `--profile` | `FILE.icc` | auto-discovered | Force a specific CMYK profile |
| `-q`, `--quality` | `1`–`100` | `92` | JPEG quality. Ignored for TIFF |
| `-r`, `--recursive` | — | off | Descend into subfolders |
| `-h`, `--help` | — | — | Usage. Works without ImageMagick installed |

Format routing (PNG → TIFF, vector and RAW skipped) is documented once, in
**[format-behavior.md](skills/convert-to-cmyk/references/format-behavior.md)**.

### Example output

```
Profile: /Library/Application Support/Adobe/Color/Profiles/Recommended/USWebCoatedSWOP.icc
Output:  print-ready
----------------------------------------
  OK   logo.png  ->  logo.tif
  OK   hero.jpg  ->  hero.jpg
  SKIP (vector — needs a vector pipeline): brandmark.svg
  SKIP (RAW — develop to TIFF first): shot_0042.cr2
----------------------------------------
Converted: 2   Skipped: 2   Failed: 0
```

## Configuration

| Setting | Default | What it unlocks |
|---------|---------|-----------------|
| `SWOP_PROFILE` env var | unset | A permanent default profile, so you never pass `-p`. Without it the script auto-discovers, then falls back to Generic CMYK. |
| `profiles/*.icc` | empty | Drop a profile in and it is found first. Gitignored — see the licensing note below. |

Full details in [docs/configuration.md](docs/configuration.md).

## Color accuracy

**RGB → CMYK is not lossless.** Saturated RGB falls outside CMYK's printable gamut and is
mapped to the nearest printable equivalent.

Profile resolution, first match wins: `-p` → `$SWOP_PROFILE` → `profiles/` → Adobe/ColorSync
locations → **macOS Generic CMYK** (approximate; warns loudly).

> **Ask your print vendor which profile they want.** Many supply one tuned to their press and
> paper. If they do, use it with `-p` — it beats generic SWOP every time.

## Safety and limits

**It never:** makes a network request, sends telemetry, modifies your source images, or
requires any credential. It reads the paths you name and writes to the output directory.

**It refuses to:** convert vector formats (SVG/AI/EPS/PDF) or RAW files — it skips them with a
reason rather than producing something that looks converted but isn't.

## Limitations

- **macOS only** in practice. The Generic CMYK and sRGB fallbacks are ColorSync paths.
- **Output filenames are flattened.** With `-r`, two same-named files in different
  subdirectories write to the same output path — the second silently overwrites the first,
  while the summary still counts both. Convert such folders separately until this is fixed.
- **The generic-profile warning matches on filename**, not profile contents. A generic profile
  renamed `USWebCoatedSWOP.icc` would suppress the warning while still producing generic color.
- **Rendering intent is not configurable.** Use a vendor profile that encodes the intent you need.
- **WebP support depends on your ImageMagick build.** A missing delegate shows up as `FAIL`.

## Development

```bash
bash tests/run-tests.sh                        # 43 assertions
shellcheck -S warning scripts/*.sh tests/*.sh  # lint
claude plugin validate . --strict              # manifest
```

See [docs/development.md](docs/development.md). Agent-facing conventions are in
[CLAUDE.md](CLAUDE.md).

## Contributing

Issues and pull requests welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) and the
[Code of Conduct](CODE_OF_CONDUCT.md). Security reports: [SECURITY.md](SECURITY.md).

## See also

Every project here shares one idea: a GTM system should refuse to act on data it cannot verify.

[descript-studio](https://github.com/katekruger/descript-studio) — the other tool here aimed at production work rather than revenue systems. Plain-language video editing with the same one-plan-then-autonomy shape.

## License

[MIT](LICENSE) © Kate Kruger.

**Third-party licensing.** This covers the plugin's code only. ICC color profiles are licensed
separately by their vendors and are deliberately **not** bundled here: Adobe's Color Profile
License Agreement permits distributing their profiles standalone or embedded in image files,
but forbids bundling them "incorporated into or bundled with any application software." A
plugin is application software, so `profiles/*.icc` is gitignored and you install the profile
yourself — see [the profile guide](skills/convert-to-cmyk/references/swop-profile.md).
Embedding the profile into a converted image, which is what this tool does, is permitted.
