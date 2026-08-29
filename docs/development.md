# Development

## Setup

```bash
git clone https://github.com/katekruger/cmyk-print-converter.git
cd cmyk-print-converter
brew install imagemagick        # the only dependency
bash scripts/rgb2cmyk.sh --help
```

Optional but recommended:

```bash
brew install shellcheck         # CI runs it at -S warning
```

## The loop

```bash
bash tests/run-tests.sh                 # 43 assertions, generates its own fixtures
bash -n scripts/rgb2cmyk.sh             # syntax
shellcheck -S warning scripts/*.sh tests/*.sh
claude plugin validate . --strict
claude plugin validate .claude-plugin/marketplace.json --strict
bash scripts/check-versions.sh
```

CI runs all of the above on every push and pull request.

## Testing the plugin end to end

```bash
claude --plugin-dir .
```

Then ask it to convert an image. `/reload-plugins` picks up edits without a restart.

To test the packaged bundle instead:

```bash
bash scripts/build-plugin.sh
claude --plugin-dir dist/cmyk-print-converter.plugin
```

## Adding or changing a skill

1. Skills live at `skills/<name>/SKILL.md`. The directory name must match frontmatter `name`.
2. The `description` states **when to fire**, not what the skill does. Start with "Use when"
   and enumerate the phrasings and situations. Never summarize the procedure there — an agent
   that reads a workflow summary in the description will follow the summary and skip the body.
3. Keep the body under 500 words. Reference material of 100+ lines goes in `references/`.
4. Do not duplicate prose between `SKILL.md`, `README.md`, and `docs/`. One canonical home,
   links from everywhere else.
5. **A skill change needs a corresponding test.** If behavior changed, `tests/run-tests.sh`
   must assert the new behavior.
6. Renaming a skill changes its invocation name. That is a breaking change: note it in
   `CHANGELOG.md` under `### Breaking` and bump the minor version.

## Changing the converter

- Keep it **bash 3.2 compatible** — macOS still ships 3.2. No associative arrays, no
  `${var,,}`, no `mapfile`. Expand possibly-empty arrays as `${arr[@]+"${arr[@]}"}`.
- Avoid GNU-only coreutils behavior. `sed -i` and `head -n -N` differ on macOS; the build
  script uses `awk` for exactly this reason.
- Adding a flag means updating three places: the script's own `--help` header, the README
  options table, and `docs/configuration.md`. CI does not catch that drift — reviewers must.

## Releasing

```bash
scripts/bump-version.sh 0.2.0     # updates both manifests and the README badge
# add a CHANGELOG entry under the new heading
git commit -am "chore: release v0.2.0"
git tag v0.2.0 && git push --tags
```

CI builds the bundle as an artifact; attach it to the GitHub release. Never commit the
`.plugin` file — it is generated output.

## House rules

- **Never commit an `.icc` profile.** Adobe's license forbids redistributing theirs bundled
  inside application software. `profiles/*.icc` is gitignored deliberately.
- **Do not overstate the tool.** RGB→CMYK is lossy and PNG cannot hold CMYK. The docs say so
  plainly and should keep saying so.
- **Every documented claim must be traceable to the code.** If a README line no longer matches
  `rgb2cmyk.sh`, that is a defect, not a style question.
