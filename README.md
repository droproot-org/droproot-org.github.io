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

--------------------------------------------------

## 2. Build clean static site (URLs + assets)

Run the single build script that:

- Converts `.html` pages into clean URLs  
  (`/services.html` → `/services/index.html`)
- Updates internal links to `/services`, `/contact`, etc.
- Preserves `/sitemap.html` at the root
- Fixes asset paths for subpages one level deep
- Does NOT modify root assets incorrectly

Run from the directory that contains the downloaded site folder:

```bash
./build-static-site.sh


--------------------------------------------------

## 3. Rename site folder to match GitHub convention

Run:

```mv my-cms.ddev.site docs```

## 4. Test locally with a Python web server

Change into the site directory:

```cd docs```

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

