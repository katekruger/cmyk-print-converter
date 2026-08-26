# Security policy

## Supported versions

The latest release on `main` is the only supported version.

| Version | Supported |
|---------|-----------|
| 0.1.x   | ✅        |

## Reporting a vulnerability

Report privately through GitHub's
[private vulnerability reporting](https://github.com/katekruger/rgbtocmykplugin/security/advisories/new)
— do not open a public issue for a security problem.

Expect an acknowledgement within **7 days** and an assessment within **30 days**.

## What this plugin does and does not touch

Worth being precise, because it runs a shell script over your files:

**It does:**
- Read the image files and directories you point it at
- Write converted images into the output directory you name (default `./cmyk-out`)
- Shell out to ImageMagick (`magick`) to perform the conversion
- Read ICC profile files from your ColorSync/Adobe profile directories

**It does not:**
- Make any network request. There is no telemetry, no upload, no update check.
- Read or write anything outside the input paths and the output directory
- Require, store, or transmit any credential, token, or API key
- Modify your source images — conversion always writes new files

## In scope

- Path traversal or command injection via crafted filenames
- Writing outside the specified output directory
- Anything causing the tool to transmit data off the machine

## Out of scope

- Vulnerabilities in ImageMagick itself — report those to
  [ImageMagick](https://github.com/ImageMagick/ImageMagick/security)
- Color inaccuracy. RGB→CMYK is lossy by nature; see the README.
- Output filename collisions when batching (a known defect, tracked as a bug, not a
  vulnerability)
