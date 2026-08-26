# Format behavior

The canonical statement of what each input format converts to. The README links here;
do not restate this table elsewhere.

| Input | Output | Why |
|-------|--------|-----|
| JPEG | CMYK JPEG | Lossy, but JPEG supports CMYK |
| TIFF | CMYK TIFF | Best choice for print |
| PNG / BMP / GIF / WebP | CMYK **TIFF** | These formats cannot store CMYK at all |
| SVG / AI / EPS / PDF | *skipped* | Vector — needs a prepress pipeline, not a raster convert |
| RAW (CR2/NEF/ARW/DNG/RAF/ORF/RW2) | *skipped* | Develop to TIFF first |
| anything else | *skipped* | Reported as `SKIP (unsupported .ext)` |

## There is no such thing as a CMYK PNG

PNG has no CMYK color type. A PNG handed to this tool comes back as a `.tif`.
Never describe that as "converted to a CMYK PNG" — it is a CMYK TIFF, and saying
otherwise misleads the user about what they can send to a printer.

## Bit depth

Sources below 8 bits per channel are raised to 8 before writing. Without that, a 1-bit
source (line art, a bilevel scan) writes its CMYK result at 1 bit per channel and the
color is destroyed — bright green comes out pure yellow.

Genuine 16-bit sources are preserved at 16 bits and never downgraded; professional
print scans depend on that.

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Ran to completion (including runs where some files were skipped) |
| `1` | Usage error, unknown option, missing ImageMagick, or unreadable profile |
