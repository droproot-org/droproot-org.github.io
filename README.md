# Static Drupal to GitHub Pages Workflow

This project provides a single script that converts a local or development Drupal site into a clean-URL static site that works correctly on GitHub Pages.

The entire process is automated: downloading the site, restructuring URLs, fixing links and assets, and producing a ready-to-deploy docs/ directory.

## Requirements

You will need the following installed:

- Bash
- wget
- curl
- macOS or Linux

## Usage

From the directory containing build-static-site.sh, run:

./build-static-site.sh https://my-cms.ddev.site

The URL must include http:// or https://.

## What the script does

### Validation

- Ensures a URL argument is provided
- Confirms the URL is well-formed
- Verifies the site is reachable before continuing
- Exits with an error if validation fails

### Cleanup from previous runs

- If a docs/ directory exists, it is moved to old-docs/
- If a previously downloaded site directory exists, it is deleted and overwritten
- This allows safe, repeatable re-runs

### Download the site

- Uses wget to fully mirror the site
- Downloads all required assets (CSS, JS, images)
- Converts links to local paths
- Ignores robots restrictions
- Creates a directory named after the site domain (example: my-cms.ddev.site/)

### Build clean URLs

- Converts root-level .html pages into clean URLs
- Example: /services.html -> /services/index.html
- Preserves /index.html
- Preserves /sitemap.html at the root

### Fix internal links

- Updates internal links to use clean paths
- Example: /services.html -> /services
- Ensures /sitemap.html always points to the root file

### Fix asset paths

- Adjusts CSS, JS, and image paths for subpages one level deep
- Ensures assets load correctly on pages like /services or /contact

### Finalize output

- Renames the processed site directory to docs/
- docs/ is ready for GitHub Pages deployment

## Testing locally

To preview the site before deploying:

cd docs
python3 -m http.server 8000 --bind 127.0.0.1

Open in your browser:

- http://localhost:8000
- http://localhost:8000/services
- http://localhost:8000/contact
