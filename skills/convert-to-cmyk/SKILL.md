---
name: convert-to-cmyk
description: Use when the user has one or more raster images and wants them prepared for print — "convert to CMYK", "make this print-ready", "prepare for print", "change the color profile for the printer", "convert color mode", "get this ready for the printer" — or uploads an image and asks whether it can go to a print vendor. Also use when the user asks which color profile a printer needs, or why print colors look duller than screen colors.
---

# Convert to CMYK for print

Convert RGB raster images to print-ready CMYK using a real ICC profile, embedding the
profile so the print vendor reads colors correctly. Default profile: **US Web Coated (SWOP)**.

## Steps

1. **Resolve the inputs.** Get the path(s) to the uploaded file(s) or folder. If the user
   dropped files into the chat, use the local paths the host provides.

2. **Check the engine.** Run `command -v magick`. If missing, tell the user to run
   `brew install imagemagick` once, then stop. Do not attempt an unmanaged conversion —
   it would not be color-managed, and the output would be wrong in a way that is hard to see.

3. **Convert.**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/rgb2cmyk.sh" <input-path(s)> -o <output-dir>
   ```
   Default the output directory to `cmyk-out` beside the input unless the user names one.
   Add `-r` to recurse, `-q N` to set JPEG quality, `-p <file.icc>` to force a profile.

4. **Report what happened.** State which files converted, where they were written, and what
   each became — including the format change and its reason, e.g. "logo.png → logo.tif,
   because PNG cannot hold CMYK". List every SKIPPED file with its reason.

5. **Be honest about the profile.** If the script warned that it fell back to Generic CMYK,
   say so plainly: the output is approximate, not press-accurate. Point the user at
   `references/swop-profile.md`.

6. **Set expectations on color.** If the user is surprised that colors look duller, explain
   that out-of-gamut RGB cannot be reproduced in print. This is physics, not a defect.

## Before converting

Tell the user what will happen to formats that cannot hold CMYK, so a `.tif` coming back
is not a surprise. The full table is in
[`references/format-behavior.md`](references/format-behavior.md).

## Reference

- [`references/format-behavior.md`](references/format-behavior.md) — format routing, bit-depth handling, exit codes
- [`references/swop-profile.md`](references/swop-profile.md) — obtaining and installing the real SWOP profile
