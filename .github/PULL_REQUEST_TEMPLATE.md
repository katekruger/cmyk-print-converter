## What changed

<!-- One paragraph. What is different after this PR. -->

## Why

<!-- The problem this solves. Link an issue if there is one. -->

## How it was tested

<!-- Paste the output of `bash tests/run-tests.sh`. If you changed conversion behavior,
     say which formats and bit depths you exercised. -->

```

```

## Checklist

- [ ] `bash tests/run-tests.sh` passes
- [ ] `claude plugin validate . --strict` passes
- [ ] `bash scripts/check-versions.sh` passes
- [ ] Docs updated — README, `docs/`, and the skill's `references/` where relevant
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] Version bumped with `scripts/bump-version.sh` if this is a release
- [ ] No ICC profile committed (`profiles/*.icc` is gitignored on purpose)
- [ ] Any new shell script has a shebang and mode `100755`
