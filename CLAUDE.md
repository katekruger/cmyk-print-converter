# CLAUDE.md

Instructions for an agent working **on this repository**. For using the plugin, see the README.

## What this repo is

A single Claude Code plugin, `cmyk-print-converter`, that converts RGB raster images to
print-ready CMYK through a real ICC profile. The repo root **is** the plugin: the manifest is
at `.claude-plugin/plugin.json` and skills at `skills/`, so it installs directly from the
GitHub URL.

Repo name is `rgbtocmykplugin`; plugin name is `cmyk-print-converter`. Both are correct in
their own context — use the repo name in URLs and clone commands, the plugin name in install
commands and skill namespacing. Do not rename either.

## Layout

| Path | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Manifest. Version lives here. |
| `.claude-plugin/marketplace.json` | Self-marketplace, `source: "./"` |
| `skills/convert-to-cmyk/SKILL.md` | The only skill |
| `skills/convert-to-cmyk/references/` | Format behavior and SWOP profile guidance |
| `scripts/rgb2cmyk.sh` | The converter. Standalone-usable. |
| `scripts/build-plugin.sh` | Rebuilds the committed bundle; `--check` fails if it is stale. |
| `scripts/check-versions.sh` / `bump-version.sh` | Version sync |
| `profiles/` | Drop-in `.icc` location. **Never commit a profile here.** |
| `cmyk-print-converter.plugin` | The packaged bundle. **Committed**, kept in sync by CI. |
| `tests/run-tests.sh` | The whole test suite |
| `docs/` | architecture, configuration, development |

## Commands

```bash
bash tests/run-tests.sh                              # tests (needs ImageMagick)
bash -n scripts/*.sh tests/*.sh                      # syntax
shellcheck -S warning scripts/*.sh tests/*.sh        # lint
claude plugin validate . --strict                    # manifest
bash scripts/check-versions.sh                       # versions agree
scripts/bump-version.sh <x.y.z>                      # release bump
```

## Runtime requirements

There is **no Python** in this repo and no package manifest — deliberately. The plugin is
`bash` plus ImageMagick, and nothing else. Do not add a `pyproject.toml`, a lockfile, or a
Python floor to match the sibling repos; there is nothing here for them to describe. The two
real constraints are:

- **bash 3.2**, because macOS still ships it (see rule 5)
- **ImageMagick 7** (`magick`), with `little-cms2` for the ICC transforms. The script also
  accepts a v6 `convert` binary as a fallback.

## Rules

1. **A skill change requires a corresponding test.** No exceptions. `tests/run-tests.sh` is
   the only suite; add the assertion there.
2. **Skill descriptions describe triggers, not procedure.** Start with "Use when". A
   description that summarizes the workflow causes agents to follow the summary and skip the
   skill body.
3. **Never commit an `.icc` profile.** Adobe's Color Profile License Agreement forbids
   bundling theirs inside application software. `profiles/*.icc` is gitignored on purpose,
   and this is why the LICENSE is plain MIT with no addendum — an earlier ICC note broke
   GitHub's license detection.
4. **The `.plugin` bundle IS committed, and must be rebuilt whenever packaged source
   changes.** The README ships it as an install path, so it stays tracked. Run
   `scripts/build-plugin.sh` after editing anything under `.claude-plugin/`, `skills/`,
   `scripts/rgb2cmyk.sh`, `README.md`, or `LICENSE`, and commit the result. CI runs
   `scripts/build-plugin.sh --check` and fails the build if the two have drifted, so this
   cannot go stale silently.
5. **bash 3.2 compatibility is required** (macOS ships 3.2), and avoid GNU-only coreutils
   flags — `sed -i` and `head -n -N` differ on macOS.
6. **Adding a flag means updating three places:** the script's `--help` header, the README
   options table, and `docs/configuration.md`. CI does not catch this drift.
7. **Do not duplicate prose.** The format-behavior table lives once, in
   `skills/convert-to-cmyk/references/format-behavior.md`. Link to it; do not restate it.
8. **Every claim in the docs must be traceable to the code.** A README line that no longer
   matches `rgb2cmyk.sh` is a defect to fix, not prose to preserve.

## Known defect

Output filenames are flattened. With `-r`, two same-named files in different subdirectories
write to the same output path; the second silently overwrites the first while the summary
counts both. Documented in the README's Limitations section. Fixing it is a design decision
(mirror the input tree, or disambiguate names) — do not pick one unilaterally.
