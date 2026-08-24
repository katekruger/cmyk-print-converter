# Installing the real US Web Coated (SWOP) profile

The plugin works out of the box, but for **press-accurate** SWOP output it needs the actual
`USWebCoatedSWOP.icc` profile. Without it, the script falls back to macOS's *Generic CMYK*
profile (a rough approximation) and prints a warning on every run.

## Why the profile is NOT bundled inside this plugin

Adobe's Color Profile License Agreement permits distributing the profile only **(a) embedded
within image files** or **(b) on a standalone basis** — and *explicitly forbids* bundling it
"incorporated into or bundled with any application software." A plugin is application software,
so shipping the `.icc` inside the `.plugin` would violate the license. Instead, install it
**standalone** into your system profiles folder (below); the plugin then auto-discovers it.
Converting an image and embedding the profile in the output is allowed under clause (a).

## Option A — you already have Adobe apps

If Photoshop, Illustrator, InDesign, or Acrobat is installed, the profile is already on disk.
The script auto-discovers it in these locations:

- `/Library/Application Support/Adobe/Color/Profiles/Recommended/USWebCoatedSWOP.icc`
- `~/Library/Application Support/Adobe/Color/Profiles/USWebCoatedSWOP.icc`
- inside `/Applications/Adobe …` app bundles

Nothing to do — just run the conversion.

## Option B — download Adobe's free ICC profile pack

Adobe distributes these profiles free (royalty-free license to use and reproduce):

- **Download page:** https://www.adobe.com/support/downloads/iccprofiles/iccprofiles_win.html
  (the pack is the same on Mac and Windows — the `.icc` files are cross-platform)

After downloading, place `USWebCoatedSWOP.icc` in either:

- `~/Library/ColorSync/Profiles/`  (so every app, including this plugin, finds it), **or**
- the plugin's own `profiles/` folder, **or**
- anywhere, and point to it: `-p /path/to/USWebCoatedSWOP.icc`

To make it the permanent default without flags:

```bash
export SWOP_PROFILE="$HOME/Library/ColorSync/Profiles/USWebCoatedSWOP.icc"
```

## Option C — ask your print vendor

Many print shops supply their own ICC profile tuned to their press and paper stock. If they
do, use that instead of generic SWOP — it is the most accurate option:

```bash
bash rgb2cmyk.sh assets/ -o cmyk-out -p /path/to/their-profile.icc
```
