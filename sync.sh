#!/bin/bash
set -euo pipefail

# Change to the script's directory (hugo-blog root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# =============================================================================
# Script Options
# =============================================================================

DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            echo "🏃 Dry-run mode enabled - no changes will be committed or pushed"
            shift
            ;;
        --help|-h)
            echo "Usage: ./sync.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run, -n    Preview changes without committing or pushing"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  OBSIDIAN_POSTS        Path to Obsidian posts folder"
            echo "  OBSIDIAN_ATTACHMENTS  Path to Obsidian attachments folder"
            echo "  HUGO_POSTS            Path to Hugo posts destination"
            echo "  HUGO_IMAGES           Path to Hugo images destination"
            echo "  MYREPO                GitHub repository URL"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# =============================================================================
# Configuration (can be overridden via environment variables)
# =============================================================================

# Obsidian paths
OBSIDIAN_POSTS="${OBSIDIAN_POSTS:-/home/ozy/Obsidian/SecondBrain/Posts}"
OBSIDIAN_ATTACHMENTS="${OBSIDIAN_ATTACHMENTS:-/home/ozy/Obsidian/SecondBrain/attachments}"

# Hugo paths
HUGO_POSTS="${HUGO_POSTS:-/home/ozy/git/hugo-blog/content/blog}"
HUGO_IMAGES="${HUGO_IMAGES:-/home/ozy/git/hugo-blog/static/images}"

# GitHub repo
MYREPO="${MYREPO:-https://github.com/ozy-ahmad/hugo-blog}"

# =============================================================================
# Pre-flight checks
# =============================================================================

echo "🔍 Checking required commands..."
for cmd in git rsync python3 gh; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ $cmd is not installed or not in PATH."
        exit 1
    fi
done
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ gh is not logged in. Run: gh auth login"
    exit 1
fi
echo "✅ All required commands available."

# Check and install Pillow for image compression
echo "🐍 Checking Python dependencies..."
if ! python3 -c "from PIL import Image" 2>/dev/null; then
    echo "📦 Installing Pillow for image compression..."
    echo "   Run: sudo pacman -S python-pillow"
    sudo pacman -S --noconfirm python-pillow
    echo "✅ Pillow installed."
else
    echo "✅ Pillow already installed."
fi

# =============================================================================
# Step 1: Initialize Git if needed
# =============================================================================

if [ ! -d ".git" ]; then
    echo "📁 Initializing Git repository..."
    git init
    git remote add origin $MYREPO
else
    echo "✅ Git repository already initialized."
    if ! git remote | grep -q 'origin'; then
        echo "🔗 Adding remote origin..."
        git remote add origin $MYREPO
    fi
fi

# =============================================================================
# Step 1b: Start from a clean, up-to-date main
# =============================================================================

if [ "$DRY_RUN" = false ]; then
    if [ -n "$(git status --porcelain)" ]; then
        echo "❌ Working tree is not clean. Commit, stash or discard these first:"
        git status --short
        exit 1
    fi
    git switch main
    git pull --ff-only
    echo "✅ On an up-to-date main."
fi

# =============================================================================
# Step 2: Sync posts from Obsidian to Hugo
# =============================================================================

echo "📝 Syncing posts from Obsidian..."

if [ ! -d "$OBSIDIAN_POSTS" ]; then
    echo "❌ Source path does not exist: $OBSIDIAN_POSTS"
    exit 1
fi

if [ ! -d "$HUGO_POSTS" ]; then
    echo "📁 Creating destination path: $HUGO_POSTS"
    mkdir -p "$HUGO_POSTS"
fi

# Sync posts (trailing slash on source copies contents, not the folder itself)
rsync -av --delete "$OBSIDIAN_POSTS/" "$HUGO_POSTS/"
echo "✅ Posts synced."

# =============================================================================
# Step 3: Sync attachments/images from Obsidian to Hugo
# =============================================================================

echo "🖼️  Syncing images from Obsidian..."

if [ ! -d "$OBSIDIAN_ATTACHMENTS" ]; then
    echo "⚠️  Attachments path does not exist: $OBSIDIAN_ATTACHMENTS"
    echo "   Skipping image sync..."
else
    if [ ! -d "$HUGO_IMAGES" ]; then
        echo "📁 Creating images directory: $HUGO_IMAGES"
        mkdir -p "$HUGO_IMAGES"
    fi
    
    # Copy only the images a post links to (![[name.png]] or ![[name.png|alt]]), so screenshots
    # from other vault notes never reach the public repo. --delete-excluded removes the rest.
    rsync -av --delete-excluded \
        --include-from=<(grep -ohiP '!\[\[\K[^\]|]+\.(png|jpe?g|webp|gif|svg)(?=(\|[^\]]*)?\]\])' "$OBSIDIAN_POSTS"/*.md | sed 's#.*/##; s#^#/#' | sort -u) \
        --exclude='*' \
        "$OBSIDIAN_ATTACHMENTS/" "$HUGO_IMAGES/"
    echo "✅ Images synced (only those used by posts)."
fi

# =============================================================================
# Step 4: Compress images and convert Obsidian image links
# =============================================================================

echo "🔄 Processing and compressing images..."

python3 << 'PYTHON_SCRIPT'
"""
1. Compress images in static/images (PNG/JPG)
2. Convert Obsidian image links to Hugo format
"""
import os
import re
from pathlib import Path

# Try to import Pillow for image compression
try:
    from PIL import Image
    PILLOW_AVAILABLE = True
except ImportError:
    PILLOW_AVAILABLE = False
    print("⚠️  Pillow not installed. Skipping image compression.")
    print("   Install with: pip install Pillow")

# =============================================================================
# Image Compression
# =============================================================================

def compress_images(images_dir, max_width=1200, quality=85):
    """Compress images to reduce file size."""
    if not PILLOW_AVAILABLE:
        return
    
    images_path = Path(images_dir)
    if not images_path.exists():
        return
    
    image_extensions = {'.png', '.jpg', '.jpeg', '.webp'}
    image_files = [f for f in images_path.iterdir() 
                   if f.suffix.lower() in image_extensions]
    
    if not image_files:
        print("No images to compress.")
        return
    
    print(f"Compressing {len(image_files)} image(s)...")
    
    for img_path in image_files:
        try:
            original_size = img_path.stat().st_size
            
            with Image.open(img_path) as img:
                # Convert RGBA to RGB for JPEG (remove alpha channel)
                if img.mode == 'RGBA' and img_path.suffix.lower() in {'.jpg', '.jpeg'}:
                    img = img.convert('RGB')
                
                # Resize if wider than max_width
                if img.width > max_width:
                    ratio = max_width / img.width
                    new_height = int(img.height * ratio)
                    img = img.resize((max_width, new_height), Image.Resampling.LANCZOS)
                
                # Save with compression
                if img_path.suffix.lower() == '.png':
                    img.save(img_path, 'PNG', optimize=True)
                elif img_path.suffix.lower() in {'.jpg', '.jpeg'}:
                    img.save(img_path, 'JPEG', quality=quality, optimize=True)
                elif img_path.suffix.lower() == '.webp':
                    img.save(img_path, 'WEBP', quality=quality)
            
            new_size = img_path.stat().st_size
            savings = ((original_size - new_size) / original_size) * 100
            
            if savings > 0:
                print(f"  ✅ {img_path.name}: {original_size//1024}KB → {new_size//1024}KB ({savings:.1f}% smaller)")
            else:
                print(f"  ℹ️  {img_path.name}: already optimized")
                
        except Exception as e:
            print(f"  ❌ Error compressing {img_path.name}: {e}")

# =============================================================================
# Convert Obsidian Image Links
# =============================================================================

def convert_obsidian_images(content):
    import urllib.parse
    pattern = r'!\[\[([^\]|]+)(?:\|([^\]]+))?\]\]'
    
    def replace_image(match):
        filepath = match.group(1).strip()
        alt_text = match.group(2)
        filename = os.path.basename(filepath)
        alt = alt_text.strip() if alt_text else os.path.splitext(filename)[0]
        # URL-encode the filename to handle spaces and special characters
        encoded_filename = urllib.parse.quote(filename)
        return f'![{alt}](/images/{encoded_filename})'
    
    return re.sub(pattern, replace_image, content)

# =============================================================================
# Main
# =============================================================================

# Compress images
compress_images('/home/ozy/git/hugo-blog/static/images')

# Process markdown files
posts_dir = Path('/home/ozy/git/hugo-blog/content/blog')
md_files = list(posts_dir.glob('**/*.md'))

print(f"\nProcessing {len(md_files)} markdown file(s)...")

for md_file in md_files:
    try:
        content = md_file.read_text(encoding='utf-8')
        if '![[' in content:
            new_content = convert_obsidian_images(content)
            if content != new_content:
                md_file.write_text(new_content, encoding='utf-8')
                print(f"  ✅ Converted links: {md_file.name}")
            else:
                print(f"  ℹ️  No changes: {md_file.name}")
        else:
            print(f"  ⏭️  Skipped: {md_file.name}")
    except Exception as e:
        print(f"  ❌ Error: {md_file.name}: {e}")

print("Done.")
PYTHON_SCRIPT

echo "✅ Images processed."

# =============================================================================
# Step 5: Open a pull request (CI builds, checks and deploys a preview)
# =============================================================================

if [ "$DRY_RUN" = true ]; then
    echo "🔍 [DRY-RUN] Would open a PR with:"
    git status --short content static
    echo ""
    echo "🏁 Dry-run complete! No branch, commit or PR was created."
    exit 0
fi

git add content static
if git diff --cached --quiet; then
    echo "ℹ️  Nothing to publish."
    exit 0
fi

BRANCH_NAME="post/$(date +%Y%m%d-%H%M%S)"
git switch -c "$BRANCH_NAME"
git commit -m "post: sync from Obsidian $(date +%F)"
git push -u origin "$BRANCH_NAME"
gh pr create --fill --base main

echo "⏳ Waiting for CI (build, link check, preview)…"
# gh pr checks errors with "no checks reported" until Actions registers the run (exit 8 = pending is fine).
# Capture the output instead of piping to grep: under set -o pipefail a pipe would report gh's failure
for _ in {1..30}; do
    out=$(gh pr checks 2>&1 || true)
    [[ "$out" == *"no checks reported"* ]] || break
    sleep 2
done
if ! gh pr checks --watch --fail-fast; then
    echo "❌ CI failed. See: gh pr checks --web"
    echo "   Fix it in Obsidian, close this PR (gh pr close $BRANCH_NAME --delete-branch), then rerun sync.sh"
    git switch main
    exit 1
fi

echo ""
echo "🔎 Preview: https://${BRANCH_NAME//\//-}.hugo-blog-ecd.pages.dev  (Cloudflare Access login)"
echo ""

read -rp "Merge and publish? [y/N] " ok
if [[ "$ok" == "y" ]]; then
    gh pr merge --squash --delete-branch      # also switches back to main and pulls
    git switch main 2>/dev/null || true
    git pull --ff-only
    echo "🚀 Merged. Watch the production deploy: gh run watch"
else
    git switch main
    echo "⏸️  Not merged. PR left open: $(gh pr view "$BRANCH_NAME" --json url --jq .url)"
fi

# =============================================================================
# Done!
# =============================================================================

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "🏁 Dry-run complete! No changes were committed or pushed."
else
    echo "🎉 All done!"
fi

