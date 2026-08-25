# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — 2026-08-25

Initial public release.

### Added
- `convert-to-cmyk` skill — triggers on natural phrasing like "convert this to CMYK for print"
- `scripts/rgb2cmyk.sh` — ImageMagick-backed RGB → CMYK converter, usable standalone
- ICC profile auto-discovery: `-p` flag → `$SWOP_PROFILE` → `profiles/` → Adobe/ColorSync
  install locations → macOS Generic CMYK fallback (with a loud warning)
- Format routing: JPEG→JPEG, TIFF→TIFF, PNG/BMP/GIF/WebP→TIFF, vector & RAW skipped with a reason
- Batch conversion over folders, with optional `-r` recursion
- `-q` JPEG quality control (default 92)
- Documentation: SWOP profile install guide, troubleshooting table, repository layout
- MIT license

### Fixed
- `--help` no longer fails on machines without ImageMagick installed — the dependency check
  now runs after argument parsing, so usage is always reachable
- `--help` no longer printed four lines of the script's own source code after the help text

[0.1.0]: https://github.com/katekruger/rgbtocmyk/releases/tag/v0.1.0
