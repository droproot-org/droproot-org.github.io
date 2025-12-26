#!/usr/bin/env bash
set -e

SITE_DIR="${1:-my-cms.ddev.site}"

if [[ ! -d "$SITE_DIR" ]]; then
  echo "✗ Error: Directory does not exist: $SITE_DIR"
  exit 1
fi

echo
echo "Static site build tasks"
echo "-----------------------"
echo "[ ] Restructure HTML pages to clean URLs"
echo "[ ] Update internal page links"
echo "[ ] Fix asset paths for subpages"
echo

############################################
# TASK 1 — Restructure HTML files
############################################

echo "▶ Restructuring pages (.html → /page/index.html)"
cd "$SITE_DIR"

shopt -s nullglob
for file in *.html; do
  [[ "$file" == "index.html" ]] && continue
  [[ "$file" == "sitemap.html" ]] && continue

  name="${file%.html}"
  mkdir -p "$name"
  mv "$file" "$name/index.html"
done
shopt -u nullglob

echo "[✓] Pages restructured"

############################################
# TASK 2 — Fix internal page links
############################################

echo "▶ Updating internal page links"

find . -name "*.html" -type f | while read -r file; do
  sed -i '' -E \
    's/href="([^":#?\/]+)\.html"/href="\/\1"/g' \
    "$file"

  # Ensure sitemap always points to root file
  sed -i '' -E \
    's/href="\/sitemap"/href="\/sitemap.html"/g' \
    "$file"
done

echo "[✓] Internal links updated"

############################################
# TASK 3 — Fix asset paths for subpages
############################################

echo "▶ Fixing asset paths for subpages"

find . -mindepth 2 -maxdepth 2 -type f -name "index.html" | while read -r file; do
  sed -i '' \
    -e 's|href="sites/|href="../sites/|g' \
    -e 's|src="sites/|src="../sites/|g' \
    -e 's|href="themes/|href="../themes/|g' \
    -e 's|src="themes/|src="../themes/|g' \
    -e 's|href="core/|href="../core/|g' \
    -e 's|src="core/|src="../core/|g' \
    "$file"
done

echo "[✓] Asset paths fixed"

############################################
# COMPLETE
############################################

echo
echo "✔ Static site build complete"
echo "✔ Clean URLs applied"
echo "✔ Assets fixed for subpages"
echo
