# CMYK Print Converter

Convert RGB images to **print-ready CMYK** with an embedded ICC color profile, right from chat.
Upload an asset, ask to "convert it to CMYK for print," and the plugin handles the rest.

## What it does

- Converts JPEG/TIFF/PNG/BMP/GIF/WebP from RGB → CMYK using a real ICC profile
- Default target profile: **US Web Coated (SWOP)** — the North American print standard
- **Embeds** the profile in the output so print vendors read colors correctly
- Matches input format where possible; routes formats that can't hold CMYK (PNG, etc.) to TIFF
- Batches whole folders; handles large files
- Cleanly skips vector (SVG/AI/EPS/PDF) and RAW files with a reason instead of producing garbage

## Install

This repo contains both the **source** and the **packaged bundle**:

- `cmyk-print-converter.plugin` — the packaged bundle, ready to install
- everything else — the unpacked source it was built from (identical contents)

Install the bundle by double-clicking `cmyk-print-converter.plugin`, or point Claude Code at
this repo directly. To rebuild the bundle after editing the source:

```bash
zip -r cmyk-print-converter.plugin \
  README.md .claude-plugin scripts skills -x '.DS_Store' '__MACOSX/*'
```

## Requirements

- **macOS** with [Homebrew](https://brew.sh)
- **ImageMagick** (one-time): `brew install imagemagick`
- *(Optional, for true SWOP accuracy)* the `USWebCoatedSWOP.icc` profile —
  see [skills/convert-to-cmyk/references/swop-profile.md](skills/convert-to-cmyk/references/swop-profile.md).
  Without it the tool uses macOS Generic CMYK and warns you.

## Usage

Just talk to it:

> "Convert this logo to CMYK for print"
> "Make these product photos print-ready"
> "Change the color profile on this folder of assets for the printer"

Or run the script directly:

```bash
bash scripts/rgb2cmyk.sh ~/assets -o ~/print-ready        # a whole folder
bash scripts/rgb2cmyk.sh logo.jpg banner.png              # individual files
bash scripts/rgb2cmyk.sh ~/assets -r                      # recurse subfolders
bash scripts/rgb2cmyk.sh ~/assets -p /path/to/profile.icc # force a specific profile
```

## Format behavior

| Input | Output | Note |
|-------|--------|------|
| JPEG  | CMYK JPEG | lossy |
| TIFF  | CMYK TIFF | best for print |
| PNG / BMP / GIF / WebP | CMYK **TIFF** | these formats can't store CMYK |
| SVG / AI / EPS / PDF | skipped | vector — needs a prepress pipeline |
| RAW   | skipped | develop to TIFF first |

## A note on accuracy

RGB → CMYK is **not** lossless. Some bright RGB colors fall outside CMYK's printable range and
get mapped to the nearest printable equivalent — this is normal and expected. Always ask your
print vendor which profile they want; if they supply one, use it with `-p`.
