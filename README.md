# CMYK Print Converter

**A Claude Code plugin that turns RGB images into print-ready CMYK — from chat.**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Requires](https://img.shields.io/badge/requires-ImageMagick-orange.svg)
![Version](https://img.shields.io/badge/version-0.1.1-green.svg)

Drop an image into chat, say *"convert this to CMYK for print,"* and get back a file your
print vendor can actually use — converted through a real ICC color profile, with that profile
**embedded** in the output so the press reads your colors correctly.

Works as a Claude Code plugin **or** as a standalone shell script.

---

## Quick start

```bash
# 1. Install the one dependency
brew install imagemagick

# 2. Convert something
bash scripts/rgb2cmyk.sh logo.png -o print-ready

# 3. Check the result
ls print-ready/          # -> logo.tif  (CMYK, profile embedded)
```

That's it. For press-accurate SWOP color, also install the SWOP profile —
see [Color accuracy](#color-accuracy) below.

---

## What it does

- Converts JPEG / TIFF / PNG / BMP / GIF / WebP from RGB → CMYK through a real ICC profile
- Default target: **US Web Coated (SWOP)** — the North American print standard
- **Embeds** the profile in the output so print vendors read colors correctly
- Only assumes sRGB when the source has *no* embedded profile — otherwise it respects the original
- Matches the input format where possible; routes formats that can't hold CMYK to TIFF
- Batches whole folders, optionally recursing
- Cleanly **skips** vector (SVG/AI/EPS/PDF) and RAW files with a stated reason, instead of
  silently producing garbage

---

## Requirements

| | |
|---|---|
| **OS** | macOS (the script reads macOS ColorSync profile paths) |
| **ImageMagick** | `brew install imagemagick` — required |
| **SWOP profile** | *Optional.* Without it you get macOS Generic CMYK + a loud warning. [How to install →](skills/convert-to-cmyk/references/swop-profile.md) |

---

## Install

This repo ships both the **packaged plugin** and the **source it was built from** — the two have
identical contents.

**As a Claude Code plugin** — download and open the bundle:

```bash
curl -L -O https://raw.githubusercontent.com/katekruger/rgbtocmyk/main/cmyk-print-converter.plugin
```

Then double-click `cmyk-print-converter.plugin`, or grab it from the
[Releases page](https://github.com/katekruger/rgbtocmyk/releases).

**As a plain script** — clone and run, no plugin install needed:

```bash
git clone https://github.com/katekruger/rgbtocmyk.git
cd rgbtocmyk
bash scripts/rgb2cmyk.sh --help
```

---

## Usage

### From chat (as a plugin)

Just say what you want — the skill triggers on natural phrasing:

> "Convert this logo to CMYK for print"
> "Make these product photos print-ready"
> "Change the color profile on this folder of assets for the printer"

### From the command line

```bash
bash scripts/rgb2cmyk.sh ~/assets -o ~/print-ready         # a whole folder
bash scripts/rgb2cmyk.sh logo.jpg banner.png               # individual files
bash scripts/rgb2cmyk.sh ~/assets -r                       # recurse subfolders
bash scripts/rgb2cmyk.sh ~/assets -p /path/to/profile.icc  # force a specific profile
bash scripts/rgb2cmyk.sh photo.jpg -q 100                  # max JPEG quality
```

### Options

| Flag | Argument | Default | What it does |
|------|----------|---------|--------------|
| `-o`, `--out` | `DIR` | `./cmyk-out` | Where converted files are written (created if missing) |
| `-p`, `--profile` | `FILE.icc` | auto-discovered | Force a specific CMYK profile — use the one your vendor supplies |
| `-q`, `--quality` | `1`–`100` | `92` | JPEG quality. Ignored for TIFF output |
| `-r`, `--recursive` | — | off | Descend into subfolders |
| `-h`, `--help` | — | — | Show usage |

**Environment variable** — set a permanent default profile and skip `-p` entirely:

```bash
export SWOP_PROFILE="$HOME/Library/ColorSync/Profiles/USWebCoatedSWOP.icc"
```

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

---

## Format behavior

| Input | Output | Why |
|-------|--------|-----|
| JPEG | CMYK JPEG | Lossy, but JPEG supports CMYK |
| TIFF | CMYK TIFF | Best choice for print |
| PNG / BMP / GIF / WebP | CMYK **TIFF** | These formats **cannot** store CMYK at all |
| SVG / AI / EPS / PDF | *skipped* | Vector — needs a prepress pipeline, not a raster convert |
| RAW (CR2/NEF/ARW/DNG…) | *skipped* | Develop to TIFF first |

> **There is no such thing as a CMYK PNG.** If you hand this tool a PNG, you get a TIFF back.
> Any tool that claims otherwise is lying to you.

---

## Color accuracy

**RGB → CMYK is not lossless.** Bright, saturated RGB colors fall outside CMYK's printable
gamut and get mapped to the nearest printable equivalent. This is normal, expected, and
physics — not a bug.

**Profile resolution order** — the script uses the first it finds:

1. `-p / --profile` flag
2. `$SWOP_PROFILE` environment variable
3. [`profiles/`](profiles/) folder in this repo
4. Adobe / ColorSync install locations on disk
5. **macOS Generic CMYK** — a rough approximation, and the script warns you loudly when it lands here

For press-accurate output, install the real SWOP profile:
**[skills/convert-to-cmyk/references/swop-profile.md](skills/convert-to-cmyk/references/swop-profile.md)**

> **Always ask your print vendor which profile they want.** Many supply one tuned to their
> specific press and paper stock — if they do, use it with `-p`. It beats generic SWOP every time.

---

## Troubleshooting

| Symptom | Cause & fix |
|---------|-------------|
| `ERROR: ImageMagick not found` | Run `brew install imagemagick` |
| `⚠️ Using the GENERIC CMYK profile` | The real SWOP profile isn't installed. Output is approximate — [install it](skills/convert-to-cmyk/references/swop-profile.md) or pass `-p` |
| `ERROR: CMYK profile not found` | The path passed to `-p` (or `$SWOP_PROFILE`) doesn't exist. Check the path |
| `SKIP (unsupported .xyz)` | Not a raster format the tool handles — see [Format behavior](#format-behavior) |
| `FAIL <file>` | ImageMagick couldn't read it. Usually a corrupt file or a format your ImageMagick build lacks a delegate for (common with WebP) |
| My PNG came back as `.tif` | Working as intended — PNG cannot store CMYK |
| Colors look duller than the original | Expected. Out-of-gamut RGB colors can't be reproduced in print |

---

## Repository layout

```
.
├── cmyk-print-converter.plugin        # packaged plugin bundle (installable)
├── .claude-plugin/
│   └── plugin.json                    # plugin manifest: name, version, description
├── skills/
│   └── convert-to-cmyk/
│       ├── SKILL.md                   # when & how Claude runs the converter
│       └── references/
│           └── swop-profile.md        # obtaining + installing the SWOP ICC profile
├── scripts/
│   └── rgb2cmyk.sh                    # the converter (usable standalone)
├── profiles/                          # drop your own .icc here (gitignored)
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE                            # MIT (code only — not the ICC profiles)
```

### Rebuilding the bundle

`cmyk-print-converter.plugin` is a zip of the source. **After editing any source file, rebuild it**
or the two will drift apart:

```bash
rm -f cmyk-print-converter.plugin
zip -r cmyk-print-converter.plugin \
  README.md LICENSE .claude-plugin scripts skills \
  -x '*.DS_Store' '__MACOSX/*'
```

---

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © Kate Kruger.

Covers this plugin's code only. ICC color profiles are licensed separately by their vendors and
are deliberately **not** bundled here — see [the profile guide](skills/convert-to-cmyk/references/swop-profile.md).
