#!/usr/bin/env bash
# Builds all three targets (macOS, Windows, web) from one clean commit, stamps each with its build
# info, and packages the itch.io upload files in builds/itch/. Serves AC D-01, D-08 (spec, M0 step 10).
set -euo pipefail

if [[ -z "${GODOT:-}" ]]; then
	echo "export_all: set GODOT to the Godot 4.5.1 executable." >&2
	exit 2
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="$ROOT/game"
BUILDS="$ROOT/builds"
INFO="$GAME/config/build_info.cfg"

require_clean_tree() {
	local dirty
	dirty="$(git -C "$ROOT" status --porcelain)"
	if [[ -n "$dirty" ]]; then
		echo "export_all: the working tree is not clean $1:" >&2
		echo "$dirty" >&2
		echo "$2" >&2
		exit 1
	fi
}

echo "== Import =="
"$GODOT" --headless --path "$GAME" --import

require_clean_tree "before exporting" "Commit or stash these first, so every build names a real commit."

# Build info. Deleted again on exit, so editor runs keep showing the dev build ID.
trap 'rm -f "$INFO"' EXIT
version="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' "$GAME/project.godot")"
commit="$(git -C "$ROOT" rev-parse --short=7 HEAD)"
date_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > "$INFO" <<EOF
[build]

version="$version"
commit="$commit"
date="$date_utc"
EOF
echo "Build $version-$commit ($date_utc)"

rm -rf "$BUILDS/macos" "$BUILDS/windows" "$BUILDS/web" "$BUILDS/itch"
mkdir -p "$BUILDS/macos" "$BUILDS/windows" "$BUILDS/web" "$BUILDS/itch"

echo "== Export macOS =="
"$GODOT" --headless --path "$GAME" --export-release "macOS" "$BUILDS/macos/TRI10NWARE.zip"
echo "== Export Windows =="
"$GODOT" --headless --path "$GAME" --export-release "Windows Desktop" "$BUILDS/windows/TRI10NWARE.exe"
echo "== Export web =="
"$GODOT" --headless --path "$GAME" --export-release "Web" "$BUILDS/web/index.html"

require_clean_tree "after exporting" \
	"The export rewrote these (usually .import or .uid files). Commit them, then run export_all.sh again."

echo "== itch.io files =="
# Web: index.html at the top level of the zip.
(cd "$BUILDS/web" && zip -q -r -X "$BUILDS/itch/TRI10NWARE_web.zip" .)

# macOS: ditto keeps the app's symlinks, permissions and signature intact.
stage="$BUILDS/itch/macos_stage"
mkdir -p "$stage"
ditto -x -k "$BUILDS/macos/TRI10NWARE.zip" "$stage"
cp "$ROOT/README.md" "$ROOT/CREDITS.md" "$stage/"
ditto -c -k --sequesterRsrc "$stage" "$BUILDS/itch/TRI10NWARE_macos.zip"
rm -rf "$stage"

# Windows: the single executable (the .pck is embedded) plus the documents.
zip -q -j -X "$BUILDS/itch/TRI10NWARE_windows.zip" \
	"$BUILDS/windows/TRI10NWARE.exe" "$ROOT/README.md" "$ROOT/CREDITS.md"

echo "export_all: done. Build $version-$commit"
ls -lh "$BUILDS/itch"
