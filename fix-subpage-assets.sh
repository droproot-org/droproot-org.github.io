#!/usr/bin/env bash
set -e

# Default site directory
SITE_DIR="${1:-my-cms.ddev.site}"

if [[ ! -d "$SITE_DIR" ]]; then
  echo "Error: Directory does not exist: $SITE_DIR"
  echo "Usage: ./fix-subpage-assets.sh [path/to/static-site-root]"
  exit 1
fi

echo "▶ Fixing assets in subpage index.html files under:"
echo "  $SITE_DIR"
echo

# Find only one-level-deep index.html files
# Matches: site/services/index.html
# Excludes: site/index.html and deeper paths
find "$SITE_DIR" -mindepth 2 -maxdepth 2 -type f -name "index.html" | while read -r file; do
  echo "▶ Processing $file"

  echo "  Before:"
  grep -E 'href="(sites|themes|core)/|src="(sites|themes|core)/' "$file" || echo "    (no matches)"

  sed -i '' \
    -e 's|href="sites/|href="../sites/|g' \
    -e 's|src="sites/|src="../sites/|g' \
    -e 's|href="themes/|href="../themes/|g' \
    -e 's|src="themes/|src="../themes/|g' \
    -e 's|href="core/|href="../core/|g' \
    -e 's|src="core/|src="../core/|g' \
    "$file"

  echo "  After:"
  grep -E 'href="\.\./(sites|themes|core)/|src="\.\./(sites|themes|core)/' "$file" || echo "    (no changes)"

  echo
done

echo "✅ Asset path fixes complete"
