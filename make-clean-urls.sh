#!/usr/bin/env bash
set -e

SITE_DIR="my-cms.ddev.site"

echo "▶ Entering site directory: $SITE_DIR"
cd "$SITE_DIR"

############################################
# PHASE 1 — Restructure HTML files
############################################

echo
echo "▶ Moving pages into folders (page.html → page/index.html)"

shopt -s nullglob
for file in *.html; do
  [[ "$file" == "index.html" ]] && continue
  [[ "$file" == "sitemap.html" ]] && continue

  name="${file%.html}"
  echo "  • $file → $name/index.html"

  mkdir -p "$name"
  mv "$file" "$name/index.html"
done
shopt -u nullglob

############################################
# PHASE 2 — Fix internal page links ONLY
############################################

echo
echo "▶ Updating internal page links (.html → clean URLs)"

find . -name "*.html" -type f | while read -r file; do
  echo "  • Processing $file"

  # Convert links like:
  #   href="services.html" → href="/services"
  # but leave sitemap.html alone
  sed -i '' -E \
    's/href="([^":#?\/]+)\.html"/href="\/\1"/g' \
    "$file"

  # Restore sitemap.html if it was touched
  sed -i '' -E \
    's/href="\/sitemap"/href="\/sitemap.html"/g' \
    "$file"
done

echo
echo "✅ DONE — clean URLs applied, assets untouched"
