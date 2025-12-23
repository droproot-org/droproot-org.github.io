# Static Drupal to GitHub Pages Workflow
=====================================

This workflow converts a local Drupal site into a clean-URL static site that works on GitHub Pages.

--------------------------------------------------

## 1. Download the site with wget

Run this from any directory:

```wget --mirror --convert-links --adjust-extension --page-requisites --no-parent --execute robots=off https://my-cms.ddev.site```

This will create a folder such as:

my-cms.ddev.site/

All pages will initially be downloaded as .html files.

--------------------------------------------------

## 2. Convert .html pages to clean URLs

Run the script that restructures pages so:

/services.html  →  /services/index.html
/contact.html   →  /contact/index.html

It also updates internal links to remove the .html extension.
This script does NOT touch CSS, JS, or other assets.

Run from the directory that contains the downloaded site folder:

``./make-clean-urls.sh``

--------------------------------------------------

## 3. Fix asset paths for subpages

Subpages such as /services and /contact need asset paths adjusted
because they now live one directory deeper.

This script:
- Runs from outside the site folder
- Finds only index.html files one directory deep
- Updates asset paths such as:

href="sites/..."   → href="../sites/..."
href="themes/..."  → href="../themes/..."
href="core/..."    → href="../core/..."

Run:

```./fix-subpage-assets.sh ./my-cms.ddev.site```

Do NOT run this script on the root index.html.

--------------------------------------------------

## 4. Test locally with a Python web server

Change into the site directory:

```cd my-cms.ddev.site```

Run:

```python3 -m http.server 8000 --bind 127.0.0.1```

Open in your browser:

http://localhost:8000
http://localhost:8000/services
http://localhost:8000/contact

--------------------------------------------------

Result

- Clean URLs with no .html extensions
- Works on GitHub Pages with a limited local function

