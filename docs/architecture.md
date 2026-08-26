# Architecture

A deliberately small plugin: one skill, one shell script, no runtime dependencies beyond
ImageMagick. There is no server, no daemon, and no network access.

## Components

```
.claude-plugin/plugin.json   manifest — identity, version, keywords
.claude-plugin/marketplace.json  self-marketplace, so the repo installs directly
skills/convert-to-cmyk/      the only skill; decides when and how to invoke the script
scripts/rgb2cmyk.sh          the converter; fully usable standalone
scripts/build-plugin.sh      packages the repo into a .plugin bundle
scripts/check-versions.sh    fails if version strings disagree
scripts/bump-version.sh      updates every version string at once
profiles/                    drop-in location for a local .icc (gitignored)
tests/run-tests.sh           43 assertions over the script and the build
```

## How a conversion happens

1. The skill fires on a print-preparation request (see its `description` for triggers).
2. It checks `command -v magick` and stops with an install instruction if absent.
3. It invokes `scripts/rgb2cmyk.sh` via `${CLAUDE_PLUGIN_ROOT}`, never an absolute path.
4. The script resolves a CMYK profile, then converts each input file in turn.
5. The skill reports what converted, what was skipped, and whether the profile was the real
   SWOP or the generic fallback.

## Profile resolution

First match wins:

1. `-p / --profile` flag
2. `$SWOP_PROFILE` environment variable
3. `profiles/USWebCoatedSWOP.icc` inside the plugin
4. Adobe and ColorSync install locations on disk
5. macOS Generic CMYK — approximate, and the script warns loudly

Step 4 ends with a `find /Applications` scan, which is slow; it only runs when the earlier,
cheaper checks miss.

## Conversion pipeline

For each file, the script builds one ImageMagick invocation:

```
magick <in> [-profile sRGB.icc] -profile <CMYK.icc> [-depth 8] [-quality N] <out>
```

- **Source profile** is applied *only* when the input carries no embedded ICC profile. An
  image that already declares its color space is trusted rather than assumed to be sRGB.
- **Depth guard** is added only when the source is below 8 bits. Without it, a 1-bit source
  writes CMYK at 1 bit per channel and the color is destroyed. A 16-bit source is left at
  16 and never downgraded.
- **Quality** applies to JPEG output only.

## Deliberate constraints

- **macOS-oriented.** The generic-CMYK and sRGB fallbacks are ColorSync paths. With an
  explicit `-p`, the script would work elsewhere, but that is untested and undocumented.
- **bash 3.2 compatible.** macOS still ships 3.2, so no associative arrays, no `${var,,}`,
  no `mapfile`. Possibly-empty arrays expand as `${arr[@]+"${arr[@]}"}` to survive `set -u`.
- **No bundled ICC profile.** Adobe's Color Profile License Agreement forbids redistributing
  their profiles inside application software. `profiles/*.icc` is gitignored for that reason.

## Known defect

Output filenames are flattened: with `-r`, two same-named files in different subdirectories
resolve to the same output path and the second silently overwrites the first, while the
summary still counts both as converted. See the README's Limitations section.
