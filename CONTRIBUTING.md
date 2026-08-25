# Contributing

Thanks for taking a look. This is a small, focused plugin — bug reports and small,
well-scoped pull requests are the most useful contributions.

## Getting set up

```bash
git clone https://github.com/katekruger/rgbtocmyk.git
cd rgbtocmyk
brew install imagemagick
bash scripts/rgb2cmyk.sh --help
```

## Before you open a PR

1. **Check the syntax:**
   ```bash
   bash -n scripts/rgb2cmyk.sh
   ```

2. **Lint it** (if you have [shellcheck](https://www.shellcheck.net)):
   ```bash
   shellcheck scripts/rgb2cmyk.sh
   ```

3. **Test a real conversion** against at least one JPEG and one PNG, and confirm the
   PNG comes back as a `.tif`:
   ```bash
   bash scripts/rgb2cmyk.sh test.jpg test.png -o /tmp/cmyk-test
   ```

4. **Rebuild the bundle if you touched any source file** — `cmyk-print-converter.plugin`
   is a zip of the source, and a PR that edits source without rebuilding leaves the two
   out of sync:
   ```bash
   rm -f cmyk-print-converter.plugin
   zip -r cmyk-print-converter.plugin \
     README.md LICENSE .claude-plugin scripts skills \
     -x '*.DS_Store' '__MACOSX/*'
   ```

5. **Update `CHANGELOG.md`** under an `## [Unreleased]` heading.

## House rules

- **Never commit an `.icc` profile.** Adobe's Color Profile License Agreement forbids
  redistributing their profiles bundled inside application software. The `profiles/`
  folder is gitignored for exactly this reason.
- **Keep `bash` 3.2 compatible.** macOS still ships bash 3.2, so no associative arrays,
  no `${var,,}`, no `mapfile`.
- **Don't overstate what the tool does.** RGB→CMYK is lossy and PNG cannot hold CMYK —
  the docs say so plainly, and they should stay that way.
- **Keep the docs in sync.** A flag added to the script needs a row in the README options
  table and a line in the script's own `--help` header.

## Reporting a bug

Please include your macOS version, `magick --version`, the exact command you ran, and the
full output — including which profile line the script printed.
