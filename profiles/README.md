# Local ICC profiles

Drop `USWebCoatedSWOP.icc` (or any other CMYK `.icc` profile) into this folder and
`rgb2cmyk.sh` will discover it automatically — this is the **first** location it checks.

Profiles in this folder are gitignored on purpose. Adobe's Color Profile License
Agreement forbids redistributing their profiles bundled inside application software,
so they must never be committed here.

See [`../skills/convert-to-cmyk/references/swop-profile.md`](../skills/convert-to-cmyk/references/swop-profile.md)
for where to get the profile and the other places the script looks for it.
