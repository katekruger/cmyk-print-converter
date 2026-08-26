#!/usr/bin/env bash
#
# Test suite for scripts/rgb2cmyk.sh
#
# Requires ImageMagick (fixtures are generated, not committed).
#   bash tests/run-tests.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/rgb2cmyk.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
ok(){ printf "  \033[32mPASS\033[0m %s\n" "$1"; PASS=$((PASS+1)); }
no(){ printf "  \033[31mFAIL\033[0m %s\n     expected: %s\n     actual:   %s\n" "$1" "$2" "$3"; FAIL=$((FAIL+1)); }
eq(){ [ "$2" = "$3" ] && ok "$1" || no "$1" "$3" "$2"; }

# Resolve ImageMagick the same way the script under test does: v7 ships `magick`,
# v6 ships `convert`/`identify`. The script advertises support for both, so the
# tests must run under both — Ubuntu's imagemagick package is still v6.
if command -v magick >/dev/null 2>&1; then
  IM="magick"; IMID="magick identify"
elif command -v convert >/dev/null 2>&1 && command -v identify >/dev/null 2>&1; then
  IM="convert"; IMID="identify"
else
  echo "ERROR: ImageMagick required (brew install imagemagick / apt-get install imagemagick)" >&2
  exit 1
fi
echo "  using: $IM ($($IMID -version 2>/dev/null | head -1))"

echo "== fixtures =="
IN="$WORK/in"; mkdir -p "$IN/nested"
$IM -size 120x90 gradient:red-blue -colorspace sRGB "$IN/photo.jpg"
$IM -size 60x40 xc:'srgb(0,255,64)' -depth 8 PNG24:"$IN/logo.png"
$IM -size 50x50 plasma:fractal -colorspace sRGB "$IN/art.tif"
$IM -size 40x40 xc:cyan -colorspace sRGB "$IN/icon.bmp"
$IM -size 40x30 xc:magenta -colorspace sRGB "$IN/frame.gif"
$IM -size 40x40 xc:'srgb(0,255,64)' "$IN/onebit.png"          # depth 1 on purpose
$IM -size 40x40 xc:'srgb(0,255,64)' -depth 16 "$IN/deep.tif"  # 16-bit on purpose
printf '<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"><rect width="8" height="8"/></svg>' > "$IN/vec.svg"
echo "raw-ish" > "$IN/shot.cr2"
echo "notes"   > "$IN/readme.txt"
$IM -size 30x30 xc:orange -colorspace sRGB "$IN/nested/subdir-only.png"
echo "  generated $(ls "$IN" | wc -l | tr -d ' ') fixtures"

echo
echo "== conversion =="
OUT="$WORK/out"
run=$(bash "$SCRIPT" "$IN" -o "$OUT" 2>&1)
eq "converted count"  "$(echo "$run" | grep -o 'Converted: [0-9]*')" "Converted: 7"
eq "skipped count"    "$(echo "$run" | grep -o 'Skipped: [0-9]*')"   "Skipped: 3"
eq "failed count"     "$(echo "$run" | grep -o 'Failed: [0-9]*')"    "Failed: 0"

echo
echo "== format routing =="
eq "jpeg stays jpeg"  "$([ -f "$OUT/photo.jpg" ] && echo y || echo n)" "y"
eq "png -> tif"       "$([ -f "$OUT/logo.tif" ]  && echo y || echo n)" "y"
eq "no cmyk png"      "$([ -f "$OUT/logo.png" ]  && echo y || echo n)" "n"
eq "tiff stays tiff"  "$([ -f "$OUT/art.tif" ]   && echo y || echo n)" "y"
eq "bmp -> tif"       "$([ -f "$OUT/icon.tif" ]  && echo y || echo n)" "y"
eq "gif -> tif"       "$([ -f "$OUT/frame.tif" ] && echo y || echo n)" "y"
eq "svg skipped"      "$([ -f "$OUT/vec.tif" ]   && echo y || echo n)" "n"
eq "raw skipped"      "$([ -f "$OUT/shot.tif" ]  && echo y || echo n)" "n"
eq "txt skipped"      "$([ -f "$OUT/readme.tif" ]&& echo y || echo n)" "n"
eq "non-recursive skips nested" "$([ -f "$OUT/subdir-only.tif" ] && echo y || echo n)" "n"

echo
echo "== every output is real CMYK with an embedded profile =="
for f in "$OUT"/*; do
  b=$(basename "$f")
  eq "$b colorspace" "$($IM "$f" -format '%[colorspace]' info:)" "CMYK"
  eq "$b has ICC"    "$([ -n "$($IM "$f" -format '%[profile:icc]' info: 2>/dev/null)" ] && echo y || echo n)" "y"
done

echo
echo "== bit-depth guard (regression: v0.1.0 crushed sub-8-bit color) =="
eq "1-bit source raised to 8" "$($IM "$OUT/onebit.tif" -format '%[depth]' info:)" "8"
px=$($IM "$OUT/onebit.tif" -format '%[pixel:p{5,5}]' info:)
eq "1-bit green not crushed to yellow" "$([ "$px" = "cmyk(0,0,255,0)" ] && echo crushed || echo ok)" "ok"
eq "16-bit source preserved" "$($IM "$OUT/deep.tif" -format '%[depth]' info:)" "16"

echo
echo "== flags =="
eq "recursive finds nested" "$(bash "$SCRIPT" "$IN" -o "$WORK/r" -r 2>&1 | grep -o 'Converted: [0-9]*')" "Converted: 8"
bash "$SCRIPT" "$IN/photo.jpg" -o "$WORK/q20"  -q 20  >/dev/null 2>&1
bash "$SCRIPT" "$IN/photo.jpg" -o "$WORK/q100" -q 100 >/dev/null 2>&1
eq "higher -q yields larger jpeg" \
   "$([ "$(wc -c < "$WORK/q100/photo.jpg")" -gt "$(wc -c < "$WORK/q20/photo.jpg")" ] && echo y || echo n)" "y"
GEN="/System/Library/ColorSync/Profiles/Generic CMYK Profile.icc"
if [ -f "$GEN" ]; then
  eq "-p selects the named profile" \
     "$(bash "$SCRIPT" "$IN/logo.png" -o "$WORK/p" -p "$GEN" 2>&1 | grep -c "Profile: $GEN")" "1"
fi

echo
echo "== exit codes and errors =="
bash "$SCRIPT" >/dev/null 2>&1;                             eq "no args -> 1"        "$?" "1"
bash "$SCRIPT" "$IN/photo.jpg" --bogus >/dev/null 2>&1;     eq "bad option -> 1"     "$?" "1"
bash "$SCRIPT" "$IN/photo.jpg" -p /nope.icc >/dev/null 2>&1;eq "missing profile -> 1" "$?" "1"
bash "$SCRIPT" --help >/dev/null 2>&1;                      eq "--help -> 0"         "$?" "0"
bash "$SCRIPT" "$IN" -o "$WORK/ok" >/dev/null 2>&1;         eq "success -> 0"        "$?" "0"
eq "--help emits no source code" \
   "$(bash "$SCRIPT" --help 2>&1 | grep -c 'set -euo pipefail')" "0"

echo
echo "== profile-absent behaviour (the default state on a fresh install) =="
# No SWOP profile installed: must still convert, but warn loudly and namefully.
warn=$(SWOP_PROFILE="" bash "$SCRIPT" "$IN/logo.png" -o "$WORK/nowarn" 2>&1)
case "$warn" in
  *"GENERIC CMYK"*) ok "generic fallback warns the user" ;;
  *) no "generic fallback warns the user" "a GENERIC CMYK warning" "no warning emitted" ;;
esac
case "$warn" in
  *USWebCoatedSWOP.icc*) ok "warning names the profile to install" ;;
  *) no "warning names the profile to install" "USWebCoatedSWOP.icc mentioned" "not mentioned" ;;
esac
eq "still converts without the profile" "$([ -f "$WORK/nowarn/logo.tif" ] && echo y || echo n)" "y"

# Profile explicitly named but missing: must fail with an actionable message, not a stack trace.
err=$(bash "$SCRIPT" "$IN/logo.png" -o "$WORK/err" -p /nonexistent/Missing.icc 2>&1 || true)
case "$err" in
  *"CMYK profile not found"*/nonexistent/Missing.icc*) ok "missing profile names the path it looked for" ;;
  *) no "missing profile names the path it looked for" "error naming /nonexistent/Missing.icc" "$err" ;;
esac

echo
echo "== documented options all exist in the script =="
# Flags appear in a case statement as alternations (-o|--out), so match the token
# followed by either "|" or ")" rather than assuming it terminates the pattern.
for flag in -o --out -p --profile -q --quality -r --recursive -h --help; do
  n=$(grep -cE "^[[:space:]]*(-[a-z]\|)?${flag}[|)]" "$SCRIPT" || true)
  [ "$n" -ge 1 ] && ok "script implements $flag" || no "script implements $flag" ">=1 case branch" "$n"
done

# And the reverse: every flag the README documents is one the script accepts.
for flag in --out --profile --quality --recursive --help; do
  n=$(grep -c -- "\`$flag\`" README.md || true)
  [ "$n" -ge 1 ] && ok "README documents $flag" || no "README documents $flag" ">=1 mention" "$n"
done

echo
echo "== build script =="
bash "$REPO_ROOT/scripts/build-plugin.sh" -o "$WORK/b.plugin" >/dev/null 2>&1
eq "build produces a bundle" "$([ -s "$WORK/b.plugin" ] && echo y || echo n)" "y"
eq "bundle carries the manifest" "$(unzip -l "$WORK/b.plugin" | grep -c 'plugin.json')" "1"
eq "bundle carries the skill"    "$(unzip -l "$WORK/b.plugin" | grep -c 'SKILL.md')" "1"
eq "bundle excludes tests"       "$(unzip -l "$WORK/b.plugin" | grep -c 'tests/')" "0"

echo
echo "════════════════════════════════════"
printf "  %d passed, %d failed\n" "$PASS" "$FAIL"
echo "════════════════════════════════════"
[ "$FAIL" -eq 0 ]
