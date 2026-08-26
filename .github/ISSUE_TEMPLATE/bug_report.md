---
name: Bug report
about: Something converted wrong, failed, or behaved unexpectedly
title: ''
labels: bug
---

**What happened**

<!-- What went wrong, in one or two sentences. -->

**Version and install method**

- Plugin version: <!-- from .claude-plugin/plugin.json, or the release you installed -->
- Installed via: <!-- marketplace / .plugin bundle / git clone -->
- OS and version: <!-- e.g. macOS 15.4 -->
- `magick --version`: <!-- first line -->

**The exact command you ran**

```bash

```

**Full output**

<!-- Paste everything, including the "Profile:" line — which profile was used often
     explains the result. -->

```

```

**Expected**

<!-- What you expected instead. -->

**Input files**

- Format and bit depth if known: <!-- `magick identify -format '%[colorspace] %[depth]' yourfile` -->
- Were you converting a folder, individual files, or using `-r`?

**Before filing**

- [ ] I checked the [format behavior table](https://github.com/katekruger/rgbtocmykplugin/blob/main/skills/convert-to-cmyk/references/format-behavior.md) — a PNG coming back as a `.tif` is expected
- [ ] I read the "Color accuracy" section of the README — duller print colors are expected
