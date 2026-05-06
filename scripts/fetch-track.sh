#!/usr/bin/env bash
# fetch-track.sh — pull a circuit SVG from julesr0y/f1-circuits-svg and
# normalise it so it tints with currentColor inside the infographic.
#
# Usage:
#   ./scripts/fetch-track.sh suzuka
#   ./scripts/fetch-track.sh miami
#
# The script:
#   1. Downloads the SVG from the julesr0y repo (CC BY-SA 4.0)
#   2. Replaces all stroke=#... with stroke=currentColor so CSS can tint it
#   3. Removes any width/height attributes so the SVG fills its container
#   4. Saves to assets/tracks/{slug}.svg

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <slug>"
  echo "Example: $0 suzuka"
  exit 1
fi

SLUG="$1"
DEST="assets/tracks/${SLUG}.svg"
URL="https://raw.githubusercontent.com/julesr0y/f1-circuits-svg/main/circuits/${SLUG}.svg"

echo "Fetching ${URL}..."
TMP=$(mktemp)
if ! curl -sfL -o "$TMP" "$URL"; then
  echo "FAILED — check the slug. Browse the repo for valid names:"
  echo "  https://github.com/julesr0y/f1-circuits-svg/tree/main/circuits"
  rm -f "$TMP"
  exit 1
fi

# Some circuits have versioned layouts (e.g. monza-1, monza-2). If the bare
# slug returned a 404, you'd need to find the current layout id manually.

# Normalise: stroke colour → currentColor (works in both quoted and style: forms)
sed -i.bak \
  -e 's/stroke:#[0-9a-fA-F]\{3,8\}/stroke:currentColor/g' \
  -e 's/stroke="#[0-9a-fA-F]\{3,8\}"/stroke="currentColor"/g' \
  "$TMP"

# Strip fixed width/height so it scales to its parent
sed -i.bak \
  -e 's/ width="[0-9]*"//g' \
  -e 's/ height="[0-9]*"//g' \
  "$TMP"

mkdir -p "$(dirname "$DEST")"
mv "$TMP" "$DEST"
rm -f "${TMP}.bak"

echo "Saved to ${DEST}"
echo ""
echo "Don't forget to credit julesr0y/f1-circuits-svg (CC BY-SA 4.0) in the repo footer."
