# Configuration

There is no config file. Behavior is set by flags and one environment variable.

## Flags

| Flag | Argument | Default | Effect |
|------|----------|---------|--------|
| `-o`, `--out` | `DIR` | `./cmyk-out` | Output directory, created if missing |
| `-p`, `--profile` | `FILE.icc` | auto-discovered | Force a specific CMYK profile |
| `-q`, `--quality` | `1`–`100` | `92` | JPEG quality. Ignored for TIFF output |
| `-r`, `--recursive` | — | off | Descend into subdirectories |
| `-h`, `--help` | — | — | Usage. Works without ImageMagick installed |

Note that `-o` is relative to your **current working directory**, not to the input.

## Environment variables

| Variable | Effect |
|----------|--------|
| `SWOP_PROFILE` | Absolute path to a CMYK `.icc`. Used when `-p` is absent. The way to set a permanent default. |

```bash
export SWOP_PROFILE="$HOME/Library/ColorSync/Profiles/USWebCoatedSWOP.icc"
```

## Installing a profile

The plugin runs without one, falling back to macOS Generic CMYK and warning on every run.
For press-accurate output, install the real profile — see
[`../skills/convert-to-cmyk/references/swop-profile.md`](../skills/convert-to-cmyk/references/swop-profile.md).

Three places the script will find it automatically:

1. `profiles/` inside the plugin (gitignored — safe to drop a file there)
2. `~/Library/ColorSync/Profiles/`
3. Adobe's profile directories, if you have Creative Cloud installed

## What is not configurable

- **Format routing.** PNG/BMP/GIF/WebP always become TIFF; this is a property of the formats,
  not a preference. See [format-behavior.md](../skills/convert-to-cmyk/references/format-behavior.md).
- **Rendering intent.** The ImageMagick default is used. If you need a specific intent, ask
  your print vendor for a profile that encodes it and pass it with `-p`.
- **Output filenames.** Always `<stem>.<ext>` in the output directory.

## No network configuration

The tool makes no network requests. There is nothing to proxy, allowlist, or authenticate.
