---
name: convert-to-cmyk
description: Convert uploaded images from RGB to print-ready CMYK with an embedded ICC color profile (default US Web Coated SWOP). Triggers when the user uploads or points to an image (JPEG, PNG, TIFF, etc.) and asks to "convert to CMYK", "prepare for print", "make this print-ready", "change the color profile for print", "convert color mode", or "get this ready for the printer".
---

# Convert to CMYK for Print

Convert RGB raster images to print-ready CMYK using a real ICC profile, embedding the
profile so the print vendor reads colors correctly. Default profile: **US Web Coated (SWOP)**.

## When to run

Trigger when the user supplies one or more images (uploaded, dragged in, or by path) and
wants them prepared for print / converted to CMYK / their color profile changed for a printer.

## Steps

1. **Locate the input(s).** Resolve the path(s) to the uploaded file(s) or folder. If the
   user dropped files into the chat, use the local paths provided by the host.

2. **Verify the engine is installed.** Run `command -v magick`. If missing, tell the user to
   install it once with `brew install imagemagick`, then stop. Do not attempt a naive
   conversion without ImageMagick — it would not be color-managed.

3. **Run the converter.** Execute the bundled script:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/rgb2cmyk.sh" <input-path(s)> -o <output-dir>
   ```
   - Default the output dir to a `cmyk-out` folder next to the input (or the user's chosen location).
   - The script auto-discovers a SWOP profile; if none is installed it falls back to the
     macOS Generic CMYK profile and prints a warning.
   - To force a specific profile: add `-p /path/to/USWebCoatedSWOP.icc`. The user can also set
     `export SWOP_PROFILE=/path/to/USWebCoatedSWOP.icc` once to make it the default.

4. **Report results plainly.** State which files converted, where they were written, and what
   each became (e.g. "logo.png → logo.tif, because PNG cannot hold CMYK"). Surface any
   SKIPPED files (vector/RAW) and the reason.

5. **Flag the profile honestly.** If the script warned that it used Generic CMYK instead of
   true SWOP, tell the user — output is approximate, not press-accurate. Point them to
   `references/swop-profile.md` for how to install the real profile.

## Format behavior (set expectations before running)

| Input | Output | Note |
|-------|--------|------|
| JPEG  | CMYK JPEG | lossy |
| TIFF  | CMYK TIFF | best for print |
| PNG / BMP / GIF / WebP | CMYK **TIFF** | these formats cannot store CMYK |
| SVG / AI / EPS / PDF | skipped | vector — needs a vector/prepress pipeline |
| RAW (CR2/NEF/ARW/DNG…) | skipped | develop to TIFF first |

Never claim a PNG was "converted to a CMYK PNG" — there is no such thing. It becomes a CMYK TIFF.

## Reference

- `references/swop-profile.md` — where to get the real US Web Coated (SWOP) profile and how to install it.
