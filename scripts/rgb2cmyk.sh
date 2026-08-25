#!/usr/bin/env bash
#
# rgb2cmyk — Print-ready RGB → CMYK converter (cmyk-print-converter plugin)
# ------------------------------------------------------------
# Converts raster images from RGB to CMYK using a real ICC
# color profile (default: US Web Coated SWOP), embedding the
# profile so print vendors read colors correctly.
#
# Usage:
#   rgb2cmyk.sh <file-or-folder> [more files...] [options]
#
# Options:
#   -o, --out DIR        Output directory       (default: ./cmyk-out)
#   -p, --profile FILE   CMYK .icc profile      (default: auto-discover SWOP, else Generic CMYK)
#   -q, --quality N      JPEG quality 1-100     (default: 92)
#   -r, --recursive      Recurse into subfolders
#   -h, --help           Show this help
#
# Format policy ("match input where possible"):
#   jpg/jpeg  -> CMYK JPEG
#   tif/tiff  -> CMYK TIFF
#   png       -> CMYK TIFF   (PNG cannot hold CMYK — routed to TIFF)
#   bmp/gif/webp -> CMYK TIFF (same reason)
#   svg/ai/eps/pdf/raw -> SKIPPED (vector/RAW need a different pipeline)
# ------------------------------------------------------------
set -euo pipefail

# ---- defaults ----
OUT="./cmyk-out"
QUALITY=92
RECURSIVE=0
GENERIC_CMYK="/System/Library/ColorSync/Profiles/Generic CMYK Profile.icc"
SRGB="/System/Library/ColorSync/Profiles/sRGB Profile.icc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- resolve the CMYK target profile ----
# Order: --profile flag > $SWOP_PROFILE env > bundled profiles/ > Adobe install on disk > Generic CMYK
discover_swop() {
  # 1. bundled with the plugin
  [ -f "$SCRIPT_DIR/../profiles/USWebCoatedSWOP.icc" ] && { echo "$SCRIPT_DIR/../profiles/USWebCoatedSWOP.icc"; return; }
  # 2. common Adobe / system install locations on macOS
  local candidates=(
    "/Library/Application Support/Adobe/Color/Profiles/Recommended/USWebCoatedSWOP.icc"
    "$HOME/Library/Application Support/Adobe/Color/Profiles/USWebCoatedSWOP.icc"
    "$HOME/Library/ColorSync/Profiles/USWebCoatedSWOP.icc"
    "/Library/ColorSync/Profiles/USWebCoatedSWOP.icc"
  )
  local c
  for c in "${candidates[@]}"; do [ -f "$c" ] && { echo "$c"; return; }; done
  # 3. wildcard search inside Adobe app bundles (slow path, last resort)
  c="$(find "/Applications" -iname "USWebCoatedSWOP.icc" 2>/dev/null | head -1 || true)"
  [ -n "$c" ] && { echo "$c"; return; }
}

CMYK_PROFILE="${SWOP_PROFILE:-}"
if [ -z "$CMYK_PROFILE" ]; then CMYK_PROFILE="$(discover_swop || true)"; fi
[ -z "$CMYK_PROFILE" ] && CMYK_PROFILE="$GENERIC_CMYK"

# ---- parse args ----
INPUTS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -o|--out)      OUT="$2"; shift 2;;
    -p|--profile)  CMYK_PROFILE="$2"; shift 2;;
    -q|--quality)  QUALITY="$2"; shift 2;;
    -r|--recursive) RECURSIVE=1; shift;;
    -h|--help)     sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    -*)            echo "Unknown option: $1" >&2; exit 1;;
    *)             INPUTS+=("$1"); shift;;
  esac
done

if [ ${#INPUTS[@]} -eq 0 ]; then
  echo "Usage: $0 <file-or-folder> [...] [-o OUT] [-p PROFILE.icc] [-q QUALITY] [-r]" >&2
  exit 1
fi

# ---- locate the ImageMagick binary ----
if command -v magick >/dev/null 2>&1; then IM=magick
elif command -v convert >/dev/null 2>&1; then IM=convert
else
  echo "ERROR: ImageMagick not found. Install with:  brew install imagemagick" >&2
  exit 1
fi

if [ ! -f "$CMYK_PROFILE" ]; then
  echo "ERROR: CMYK profile not found: $CMYK_PROFILE" >&2
  exit 1
fi

# ---- warn loudly if falling back to the generic (non-SWOP) profile ----
case "$CMYK_PROFILE" in
  *"Generic CMYK"*)
    echo "⚠️  Using the GENERIC CMYK profile, not true SWOP."
    echo "    Colors will be approximate. For press-accurate SWOP output, install the"
    echo "    real profile (USWebCoatedSWOP.icc) or pass:  -p /path/to/USWebCoatedSWOP.icc"
    echo "";;
esac

mkdir -p "$OUT"

gather() {
  local target="$1"
  if [ -d "$target" ]; then
    if [ "$RECURSIVE" -eq 1 ]; then find "$target" -type f
    else find "$target" -maxdepth 1 -type f; fi
  elif [ -f "$target" ]; then echo "$target"
  fi
}

CONVERTED=0; SKIPPED=0; FAILED=0

convert_one() {
  local in="$1"
  local base ext lower outfile stem
  base="$(basename "$in")"
  ext="${base##*.}"
  lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
  stem="${base%.*}"

  case "$lower" in
    jpg|jpeg)        outfile="$OUT/${stem}.jpg";;
    tif|tiff)        outfile="$OUT/${stem}.tif";;
    png|bmp|gif|webp) outfile="$OUT/${stem}.tif";;   # can't hold CMYK -> TIFF
    svg|ai|eps|pdf)  echo "  SKIP (vector — needs a vector pipeline): $base"; SKIPPED=$((SKIPPED+1)); return;;
    cr2|nef|arw|dng|raf|orf|rw2) echo "  SKIP (RAW — develop to TIFF first): $base"; SKIPPED=$((SKIPPED+1)); return;;
    *)               echo "  SKIP (unsupported .$lower): $base"; SKIPPED=$((SKIPPED+1)); return;;
  esac

  # Assume sRGB only when the source carries no embedded profile.
  local embedded src_args=()
  embedded="$("$IM" identify -format '%[profile:icc]' "$in" 2>/dev/null || true)"
  if [ -z "$embedded" ] && [ -f "$SRGB" ]; then src_args=(-profile "$SRGB"); fi

  local q_args=()
  if [ "$lower" = "jpg" ] || [ "$lower" = "jpeg" ]; then q_args=(-quality "$QUALITY"); fi

  # Output inherits the source bit depth. A 1-bit source (line art, bilevel scan)
  # would write CMYK at 1 bit per channel and crush the color — so raise sub-8-bit
  # sources to 8. Never lower a genuine 16-bit source; print work depends on it.
  local depth_args=() in_depth
  in_depth="$("$IM" identify -format '%[depth]' "$in" 2>/dev/null || echo 8)"
  case "$in_depth" in ''|*[!0-9]*) in_depth=8;; esac
  [ "$in_depth" -lt 8 ] && depth_args=(-depth 8)

  # bash 3.2-safe expansion of possibly-empty arrays under `set -u`
  if "$IM" "$in" ${src_args[@]+"${src_args[@]}"} -profile "$CMYK_PROFILE" ${depth_args[@]+"${depth_args[@]}"} ${q_args[@]+"${q_args[@]}"} "$outfile" 2>/dev/null; then
    echo "  OK   $base  ->  $(basename "$outfile")"
    CONVERTED=$((CONVERTED+1))
  else
    echo "  FAIL $base"
    FAILED=$((FAILED+1))
  fi
}

echo "Profile: $CMYK_PROFILE"
echo "Output:  $OUT"
echo "----------------------------------------"
for target in "${INPUTS[@]}"; do
  while IFS= read -r f; do
    [ -n "$f" ] && convert_one "$f"
  done < <(gather "$target")
done
echo "----------------------------------------"
echo "Converted: $CONVERTED   Skipped: $SKIPPED   Failed: $FAILED"
