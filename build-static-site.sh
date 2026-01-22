#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

LOCAL_URL="$1"
LIVE_URL="$2"

[[ -z "$LOCAL_URL" ]] && error "No LOCAL_URL provided. Usage: ./build-static-site.sh <LOCAL_URL> <LIVE_URL>"
[[ -z "$LIVE_URL" ]] && error "No LIVE_URL provided. Usage: ./build-static-site.sh <LOCAL_URL> <LIVE_URL>"

[[ ! "$LOCAL_URL" =~ ^https?:// ]] && error "Invalid LOCAL_URL format: $LOCAL_URL"
[[ ! "$LIVE_URL" =~ ^https?:// ]] && error "Invalid LIVE_URL format: $LIVE_URL"

if ! curl -Is "$LOCAL_URL" --max-time 5 | head -n 1 | grep -q "200"; then
  error "Cannot reach LOCAL_URL: $LOCAL_URL"
fi

if ! curl -Is "$LIVE_URL" --max-time 5 | head -n 1 | grep -q "200"; then
  error "Cannot reach LIVE_URL: $LIVE_URL"
fi

SITE_DIR="$(echo "$LOCAL_URL" | sed -E 's|https?://||')"

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
echo "• LOCAL_URL: $LOCAL_URL"
echo "• LIVE_URL:  $LIVE_URL"
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
  "$LOCAL_URL"

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
# REPLACE LOCAL_URL WITH LIVE_URL
############################################

echo
echo "▶ Replacing LOCAL_URL with LIVE_URL in HTML files"
echo "• From: $LOCAL_URL"
echo "• To:   $LIVE_URL"
echo

find . -type f -name "*.html" | while read -r file; do
  sed_inplace \
    -e "s|$LOCAL_URL|$LIVE_URL|g" \
    "$file"
done

echo "✔ URLs updated"

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


echo
echo "▶ Fixing JS paths (root-relative)"

find . -type f -name "*.html" | while read -r file; do
  sed_inplace \
    -e 's|src="themes/|src="/themes/|g' \
    -e 's|src="core/|src="/core/|g' \
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


echo
echo "▶ Injecting mobile menu script"

find . -type f -name "*.html" | while read -r file; do
  # Only add the script if it's not already present
  if ! grep -q 'mobile-menu.js' "$file"; then
    sed_inplace \
      -e 's|</body>|  <script src="/assets/mobile-menu.js"></script>\n</body>|i' \
      "$file"
  fi
done

echo
echo "▶ Copying assets folder into site output (non-destructive)"

if [ -d "$ROOT_DIR/assets" ]; then
  mkdir -p assets
  cp -R "$ROOT_DIR/assets/." assets/
else
  echo "⚠️  No assets folder found next to build-static-site.sh"
fi


############################################
# INJECT HEADER / LOGO LAYOUT FIX (CSS ONLY)
############################################

echo
echo "▶ Injecting header layout fix CSS"

find . -type f -name "*.html" | while read -r file; do
  if ! grep -q 'header-layout-fix' "$file"; then
    sed_inplace \
      -e '/<\/head>/i\
<style id="header-layout-fix">\
/* Establish a real vertical alignment context */\
header[role="banner"] .navbar {\
  display: flex;\
  align-items: center;\
  min-height: 72px;\
}\
\
/* Logo container should center, not stretch */\
.navbar--logo {\
  display: flex;\
  align-items: center;\
  transform: translateY(-6px);\
  padding-bottom: 2px;\
}\
\
/* Footer logo: prevent stretch on mobile */\
.site-footer .branding img {\
  height: auto !important;\
  width: auto !important;\
  max-height: 32px;\
  max-width: 100%;\
  object-fit: contain;\
  display: block;\
}\
\
/* Logo sizing: intrinsic, no overflow */\
.navbar--logo img {\
  height: auto !important;\
  width: auto !important;\
  max-height: 56px;\
  max-width: 100%;\
  object-fit: contain;\
  display: block;\
}\
\
@media (max-width: 768px) {\
  header[role="banner"] .navbar {\
    min-height: 64px;\
  }\
  .navbar--logo img {\
    max-height: 48px;\
  }\
}\
</style>' \
      "$file"
  fi
done

echo "✔ Header layout fix CSS injected"




############################################
# ENSURE OG:IMAGE META TAG
############################################

echo
echo "▶ Ensuring og:image meta tags"

find . -type f -name "*.html" | while read -r file; do
  # Skip if og:image already exists
  if grep -qi 'property=["'\'']og:image["'\'']' "$file"; then
    continue
  fi

  # Attempt to find logo image under .navbar--logo
  LOGO_SRC=$(sed -nE '
    /class=["'\''][^"'\'']*navbar--logo[^"'\'']*["'\'']/,/<\/[^>]+>/ {
      s/.*<img[^>]*src=["'\'']([^"'\'']+)["'\''].*/\1/p
    }
  ' "$file" | head -n 1)

  # Skip if no logo found
  [[ -z "$LOGO_SRC" ]] && continue

  # Ensure logo path is root-relative
  if [[ "$LOGO_SRC" != /* ]]; then
    LOGO_SRC="/$LOGO_SRC"
  fi

  OG_IMAGE_TAG="<meta property=\"og:image\" content=\"${LIVE_URL}${LOGO_SRC}\">"

  # Insert og:image immediately after og:url
  sed_inplace \
    -e "/property=[\"']og:url[\"']/a\\
$OG_IMAGE_TAG
" \
    "$file"

done

echo "✔ og:image meta tags ensured"


############################################
# FINALIZE
############################################

cd ..

echo
echo "▶ Finalizing output"
mv "$SITE_DIR" docs

############################################
# PRESERVE CNAME
############################################

echo
echo "▶ Preserving CNAME file"

if [[ -f "old-docs/CNAME" ]]; then
  cp "old-docs/CNAME" "docs/CNAME"
  echo "✔ CNAME copied from old-docs → docs"
else
  echo "• No CNAME found in old-docs (skipping)"
fi

echo
echo "✔ Static site build complete"
echo "✔ Output directory: docs/"