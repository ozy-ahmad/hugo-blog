#!/bin/bash
set -euo pipefail

# Change to the script's directory (hugo-blog root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# =============================================================================
# Configuration
# =============================================================================

# Obsidian paths
OBSIDIAN_POSTS="/home/ozy/Obsidian/SecondBrain/Posts"
OBSIDIAN_ATTACHMENTS="/home/ozy/Obsidian/SecondBrain/attachments"

# Hugo paths
HUGO_POSTS="/home/ozy/git/hugo-blog/content/posts"
HUGO_IMAGES="/home/ozy/git/hugo-blog/static/images"

# GitHub repo
MYREPO="https://github.com/ozy-ahmad/hugo-blog"

# =============================================================================
# Pre-flight checks
# =============================================================================

echo "🔍 Checking required commands..."
for cmd in git rsync python3 hugo; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ $cmd is not installed or not in PATH."
        exit 1
    fi
done
echo "✅ All required commands available."

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
    
    rsync -av --delete "$OBSIDIAN_ATTACHMENTS/" "$HUGO_IMAGES/"
    echo "✅ Images synced."
fi

# =============================================================================
# Step 4: Process Markdown files to convert Obsidian image links
# =============================================================================

echo "🔄 Processing image links in Markdown files..."

python3 << 'PYTHON_SCRIPT'
"""
Convert Obsidian image links to Hugo format.
Obsidian: ![[image.png]] or ![[image.png|alt text]]
Hugo:     ![alt text](/images/image.png)
"""
import os
import re
from pathlib import Path

def convert_obsidian_images(content):
    pattern = r'!\[\[([^\]|]+)(?:\|([^\]]+))?\]\]'
    
    def replace_image(match):
        filepath = match.group(1).strip()
        alt_text = match.group(2)
        filename = os.path.basename(filepath)
        alt = alt_text.strip() if alt_text else os.path.splitext(filename)[0]
        return f'![{alt}](/images/{filename})'
    
    return re.sub(pattern, replace_image, content)

posts_dir = Path('/home/ozy/git/hugo-blog/content/posts')
md_files = list(posts_dir.glob('**/*.md'))

print(f"Found {len(md_files)} markdown file(s).")

for md_file in md_files:
    try:
        content = md_file.read_text(encoding='utf-8')
        if '![[' in content:
            new_content = convert_obsidian_images(content)
            if content != new_content:
                md_file.write_text(new_content, encoding='utf-8')
                print(f"  ✅ Processed: {md_file.name}")
            else:
                print(f"  ℹ️  No changes: {md_file.name}")
        else:
            print(f"  ⏭️  Skipped: {md_file.name}")
    except Exception as e:
        print(f"  ❌ Error: {md_file.name}: {e}")

print("Done processing image links.")
PYTHON_SCRIPT

echo "✅ Image links processed."

# =============================================================================
# Step 5: Build the Hugo site
# =============================================================================

echo "🏗️  Building the Hugo site..."
if ! hugo; then
    echo "❌ Hugo build failed."
    exit 1
fi
echo "✅ Hugo site built."

# =============================================================================
# Step 6: Stage changes for Git
# =============================================================================

echo "📦 Staging changes for Git..."
if git diff --quiet && git diff --cached --quiet; then
    echo "ℹ️  No changes to stage."
else
    git add .
    echo "✅ Changes staged."
fi

# =============================================================================
# Step 7: Commit changes
# =============================================================================

commit_message="New Blog Post on $(date +'%Y-%m-%d %H:%M:%S')"
if git diff --cached --quiet; then
    echo "ℹ️  No changes to commit."
else
    echo "💾 Committing changes..."
    git commit -m "$commit_message"
    echo "✅ Changes committed."
fi

# =============================================================================
# Step 8: Push to main branch
# =============================================================================

echo "🚀 Deploying to GitHub Main..."
if ! git push origin main; then
    echo "❌ Failed to push to main branch."
    exit 1
fi
echo "✅ Pushed to main branch."

# =============================================================================
# Done!
# =============================================================================

echo ""
echo "🎉 All done! Site synced, processed, committed, built, and pushed to main."
