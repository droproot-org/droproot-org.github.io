#!/usr/bin/env bash
set -e

############################################
# HELPERS
############################################

error() {
  echo "✗ Error: $1"
  exit 1
}

# Cross-platform sed (macOS + Linux)
sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

############################################
# VALIDATION
############################################

URL="$1"

[[ -z "$URL" ]] && error "No site URL provided. Usage: ./build-static-site.sh https://example.com"

[[ ! "$URL" =~ ^https?:// ]] && error "Invalid URL format: $URL"

if ! curl -Is "$URL" --max-time 5 | head -n 1 | grep -q "200"; then
  error "Cannot reach site: $URL"
fi

SITE_DIR="$(echo "$URL" | sed -E 's|https?://||')"

############################################
# CLEANUP
############################################

echo
echo "▶ Cleanup"

if [[ -d "docs" ]]; then
  echo "• Moving existing docs → old-docs"
  rm -rf old-docs
  mv docs old-docs
fi

if [[ -d "$SITE_DIR" ]]; then
  echo "• Removing existing site directory: $SITE_DIR"
  rm -rf "$SITE_DIR"
fi

############################################
# DOWNLOAD SITE
############################################

echo
echo "▶ Downloading site"
echo "• URL:  $URL"
echo "• Dir:  $SITE_DIR"
echo

wget \
  --mirror \
  --convert-links \
  --adjust-extension \
  --page-requisites \
  --no-parent \
  --reject-regex='/(node|page)/[0-9]+' \
  --execute robots=off \
  "$URL"

[[ ! -d "$SITE_DIR" ]] && error "Download failed — directory not found"

############################################
# BUILD STATIC SITE
############################################

cd "$SITE_DIR"

echo
echo "▶ Restructuring HTML pages"

shopt -s nullglob
for file in *.html; do
  [[ "$file" == "index.html" || "$file" == "sitemap.html" ]] && continue
  name="${file%.html}"
  mkdir -p "$name"
  mv "$file" "$name/index.html"
done
shopt -u nullglob

echo "✔ Pages restructured"

############################################
# FIX INTERNAL LINKS
############################################

echo
echo "▶ Updating internal links"

find . -type f -name "*.html" | while read -r file; do
  sed_inplace -E 's/href="([^":#?\/]+)\.html"/href="\/\1"/g' "$file"
  sed_inplace -E 's/href="\/sitemap"/href="\/sitemap.html"/g' "$file"
done

echo "✔ Links updated"

############################################
# FIX ASSET PATHS
############################################

echo
echo "▶ Fixing asset paths (force root-relative, incl. srcset)"

find . -type f -name "*.html" | while read -r file; do
  sed_inplace \
    -e 's|href="sites/|href="/sites/|g' \
    -e 's|href="themes/|href="/themes/|g' \
    -e 's|href="core/|href="/core/|g' \
    -e 's|src="sites/|src="/sites/|g' \
    -e 's|src="themes/|src="/themes/|g' \
    -e 's|src="core/|src="/core/|g' \
    -e 's|srcset="sites/|srcset="/sites/|g' \
    -e 's|srcset="themes/|srcset="/themes/|g' \
    -e 's|srcset="core/|srcset="/core/|g' \
    -e 's|, sites/|, /sites/|g' \
    -e 's|, themes/|, /themes/|g' \
    -e 's|, core/|, /core/|g' \
    "$file"
done


echo "✔ Assets fixed"

echo
echo "▶ Fixing homepage links (/index → /)"

find . -type f -name "*.html" | while read -r file; do
  sed_inplace \
    -e 's|href="/index"|href="/"|g' \
    "$file"
done

############################################
# FINALIZE
############################################

cd ..

echo
echo "▶ Finalizing output"
mv "$SITE_DIR" docs

echo
echo "✔ Static site build complete"
echo "✔ Output directory: docs/"