#!/usr/bin/env bash
# Cuts a release in two steps (docs/RELEASING.md):
#   tools/linux/release.sh <version>            tag and build, nothing leaves this machine
#   tools/linux/release.sh <version> --publish  push and create the GitHub release
# The first needs a clean master and a "## <version>" section in CHANGELOG.md. It writes VERSION,
# commits "release: v<version>", tags v<version> and builds dist/AmmoOverhaul-<version>.zip
# (package.sh) with its .sha256. Undo it with git tag -d v<version>, plus
# git reset --hard HEAD~1 if it made the release commit.
# The second (tagging first if the tag doesn't exist yet) pushes master and the tag and creates
# the GitHub release with the zip; publishing it runs .github/workflows/nexus-upload.yml, the
# Nexus upload. A version with a suffix (0.2.0-rc.1) becomes a GitHub prerelease, not uploaded.
set -euo pipefail
source "$(dirname "$0")/common.sh"
cd "$ROOT"

version="${1:?usage: release.sh <version> [--publish]}"
publish="${2:-}"
tag="v$version"
zip="dist/AmmoOverhaul-$version.zip"

[[ "$(git branch --show-current)" == master ]] || { echo "not on master" >&2; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo "working tree not clean" >&2; exit 1; }
# The changelog section: from "## <version>" to the next "## ".
notes="$(awk -v v="## $version" '$0 == v || index($0, v " ") == 1 {on=1; next} on && /^## / {exit} on' CHANGELOG.md)"
[[ -n "${notes//[[:space:]]/}" ]] || { echo "CHANGELOG.md has no '## $version' section" >&2; exit 1; }

if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  [[ "$(git rev-parse "$tag^{commit}")" == "$(git rev-parse HEAD)" ]] || { echo "tag $tag exists and isn't HEAD" >&2; exit 1; }
  [[ -f "$zip" ]] || tools/linux/package.sh
else
  # Build first, so a failed build leaves no commit or tag (and VERSION as it was).
  echo "$version" > VERSION
  tools/linux/package.sh || { git checkout -q VERSION; exit 1; }
  git add VERSION
  # VERSION may already say it (set ahead of time): then the tag goes on HEAD as it is.
  git diff --cached --quiet || git commit -q -m "release: $tag"
  git tag -a "$tag" -m "Ammo Overhaul $version" -m "$notes"
fi

if [[ "$publish" != "--publish" ]]; then
  echo "tagged $tag and built $zip; nothing pushed. Publish with: tools/linux/release.sh $version --publish"
  exit 0
fi
[[ "$(tr -d '[:space:]' < VERSION)" == "$version" ]] || { echo "VERSION doesn't say $version" >&2; exit 1; }
pre=(); [[ "$version" == *-* ]] && pre=(--prerelease)
git push origin master "$tag"
gh release create "$tag" "$zip" "$zip.sha256" --title "Ammo Overhaul $version" --notes "$notes" "${pre[@]}"
