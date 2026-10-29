# Releasing

A release is a git tag `v<version>`, a GitHub release with the zip, and a new version of the main
file on Nexus Mods. The zip is built locally: the native plugin is cross-built against the
Windows SDK (`tools/linux/build-native.sh`), which CI doesn't have.

## Before a release

1. The full in-game suite passes on master: restart the game, then
   `tools/linux/game-lock.sh tools/snippets/calibers/suite.sh` (about an hour; don't play
   meanwhile). Close the game after.
2. The zip installs and loads: `tools/linux/package.sh`, then the smoke test below.
3. The playtest steps in `docs/TESTING.md` touched by the release have been played.
4. `CHANGELOG.md` has a `## <version>` section: what a player gets, in plain words. It becomes
   the GitHub release notes and the Nexus changelog.

## Smoke test of the zip

The suite runs on the dev deploy, which carries the test data (`test.yaml`). The zip doesn't, so
it gets its own check:

1. `tools/linux/restart-game.sh --kill`, then remove the deployed mod (`r6/scripts/AmmoOverhaul`,
   `r6/tweaks/AmmoOverhaul`, `red4ext/plugins/AmmoOverhaul`, `archive/pc/mod/AmmoOverhaul.archive`)
   and extract the zip into the game folder.
2. `tools/linux/restart-game.sh`. The newest TweakXL log has no errors, and in CET
   `TweakDB:GetFlat("AmmoOverhaul.version")` is the version.
3. `tools/linux/game-lock.sh tools/snippets/calibers/check.sh calibers/records.lua
   calibers/crafting.lua calibers/distribution.lua slice/vendors.lua` passes (none of these use
   the test data).
4. Close the game and `tools/linux/deploy.sh` to go back to the dev deploy.

## Cutting it

```
tools/linux/release.sh 0.1.0            # VERSION, commit, tag, zip; nothing pushed
tools/linux/release.sh 0.1.0 --publish  # push master and the tag, create the GitHub release
```

The first step can be undone with `git tag -d v0.1.0`, plus `git reset --hard HEAD~1` if it
made a release commit (it doesn't when `VERSION` already says the version). Publishing the
GitHub release runs `.github/workflows/nexus-upload.yml`, which checks the zip against its
`.sha256` and uploads it as a new version of the main file, with the changelog section as the
Nexus changelog. A version with a suffix (`0.2.0-rc.1`) becomes a GitHub prerelease and isn't
uploaded. To upload a release again: Actions, "Upload to Nexus Mods", Run workflow, with its tag.

## One-time Nexus setup

1. Make the mod page and upload the first zip by hand (`docs/NEXUS.md` has the page text and the
   upload settings).
2. Create an API key at https://www.nexusmods.com/settings/api-keys.
3. In the GitHub repo's settings (Secrets and variables, Actions):
   - secret `NEXUSMODS_API_KEY`;
   - variables `NEXUS_MOD_ID` (in the mod page URL) and `NEXUS_FILE_ID` (Files tab, "Advanced").

Until `NEXUS_FILE_ID` is set the upload job is skipped, so a GitHub release made before the setup
uploads nothing.
