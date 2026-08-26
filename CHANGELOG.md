# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `.claude-plugin/marketplace.json` — the plugin now installs via
  `/plugin marketplace add katekruger/rgbtocmykplugin`, which was previously impossible
- Test suite (`tests/run-tests.sh`), 43 assertions. The repo previously had none
- CI: manifest validation (`claude plugin validate --strict`), JSON parsing, shellcheck,
  executable-bit checks, the test suite against a real ImageMagick, bundle build, and a
  gitleaks secret scan
- Version synchronization: `.version-bump.json`, `scripts/check-versions.sh` (enforced in
  CI), and `scripts/bump-version.sh`
- `scripts/build-plugin.sh` — rebuilds the committed bundle, with a `--check` mode that fails
  when the bundle has drifted from source. Enforced in CI, so the tracked bundle can no longer
  go stale silently (it previously relied on a human remembering to re-zip)
- `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CLAUDE.md`, `AGENTS.md`, `.gitattributes`
- `docs/architecture.md`, `docs/configuration.md`, `docs/development.md`
- `.github/` issue templates, PR template, and dependabot
- `skills/convert-to-cmyk/references/format-behavior.md` — the format table now has one home,
  and newly documents the bit-depth guard and exit codes

### Changed
- Manifest completed: `displayName`, `license`, `homepage`, `repository`, `author.url`. The
  description now states the capability; trigger phrasings live in the skill where they belong
- Skill description rewritten trigger-first ("Use when…"); body 412 → 301 words
- README restructured to the standard section order, with install, skills, configuration,
  safety, and limitations sections it previously lacked

### Fixed
- `scripts/build-plugin.sh` uses `awk` rather than `head -n -2`, which BSD/macOS `head`
  does not support

### Known issues
- Output filenames are flattened: with `-r`, two same-named files in different subdirectories
  write to the same output path and the second silently overwrites the first, while the
  summary counts both as converted. Newly documented; not yet fixed, because the fix is a
  design choice between mirroring the input tree and disambiguating names

## [0.1.1] — 2026-08-25

### Fixed
- **Color was crushed on sub-8-bit sources.** The output inherited the source bit
  depth, so a 1-bit input (line art, bilevel scan) had its CMYK channels written at
  1 bit each — bright green came out pure yellow. Sources below 8 bits are now raised
  to 8 before writing. Genuine 16-bit sources are left at 16 and never downgraded.

### Changed
- Verified end to end against real images: JPEG/PNG/TIFF/BMP/GIF conversion, all
  outputs confirmed 4-channel CMYK with an embedded ICC profile, plus recursion,
  `-q`, `-p`, `$SWOP_PROFILE`, skip paths, and exit codes.

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

[0.1.1]: https://github.com/katekruger/rgbtocmyk/releases/tag/v0.1.1
[0.1.0]: https://github.com/katekruger/rgbtocmyk/releases/tag/v0.1.0
