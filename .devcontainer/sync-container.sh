 #!/bin/bash
 set -euo pipefail
 
 # This script runs inside the devcontainer
 # Obsidian paths are mounted at /obsidian/
 
 SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
 cd "$SCRIPT_DIR"
 
 DRY_RUN=false
 
 while [[ $# -gt 0 ]]; do
     case $1 in
         --dry-run|-n) DRY_RUN=true; echo "🏃 Dry-run mode"; shift ;;
         --help|-h)
             echo "Usage: ./sync-container.sh [--dry-run]"
             exit 0
             ;;
         *) echo "Unknown option: $1"; exit 1 ;;
     esac
 done
 
 # Use container paths (from environment or defaults)
 OBSIDIAN_POSTS="${OBSIDIAN_POSTS:-/obsidian/Posts}"
 OBSIDIAN_ATTACHMENTS="${OBSIDIAN_ATTACHMENTS:-/obsidian/attachments}"
 HUGO_POSTS="${HUGO_POSTS:-/workspaces/hugo-blog/content/blog}"
 HUGO_IMAGES="${HUGO_IMAGES:-/workspaces/hugo-blog/static/images}"
 
 echo "📝 Syncing posts from Obsidian..."
 mkdir -p "$HUGO_POSTS"
 rsync -av --delete "$OBSIDIAN_POSTS/" "$HUGO_POSTS/"
 echo "✅ Posts synced."
 
 echo "🖼️  Syncing images..."
 if [ -d "$OBSIDIAN_ATTACHMENTS" ]; then
     mkdir -p "$HUGO_IMAGES"
     rsync -av --delete "$OBSIDIAN_ATTACHMENTS/" "$HUGO_IMAGES/"
     echo "✅ Images synced."
 else
     echo "⚠️  No attachments folder found."
 fi
 
 echo "🔄 Processing images and converting links..."
 python3 << 'PYTHON_SCRIPT'
 import os
 import re
 import urllib.parse
 from pathlib import Path
 
 try:
     from PIL import Image
     PILLOW_AVAILABLE = True
 except ImportError:
     PILLOW_AVAILABLE = False
 
 def compress_images(images_dir, max_width=1200, quality=85):
     if not PILLOW_AVAILABLE:
         return
     images_path = Path(images_dir)
     if not images_path.exists():
         return
     for img_path in images_path.iterdir():
         if img_path.suffix.lower() in {'.png', '.jpg', '.jpeg', '.webp'}:
             try:
                 original_size = img_path.stat().st_size
                 with Image.open(img_path) as img:
                     if img.mode == 'RGBA' and img_path.suffix.lower() in {'.jpg', '.jpeg'}:
                         img = img.convert('RGB')
                     if img.width > max_width:
                         ratio = max_width / img.width
                         img = img.resize((max_width, int(img.height * ratio)), Image.Resampling.LANCZOS)
                     if img_path.suffix.lower() == '.png':
                         img.save(img_path, 'PNG', optimize=True)
                     elif img_path.suffix.lower() in {'.jpg', '.jpeg'}:
                         img.save(img_path, 'JPEG', quality=quality, optimize=True)
                     elif img_path.suffix.lower() == '.webp':
                         img.save(img_path, 'WEBP', quality=quality)
                 new_size = img_path.stat().st_size
                 if original_size > new_size:
                     print(f"  ✅ {img_path.name}: {original_size//1024}KB → {new_size//1024}KB")
             except Exception as e:
                 print(f"  ❌ {img_path.name}: {e}")
 
 def convert_obsidian_images(content):
     pattern = r'!\[\[([^\]|]+)(?:\|([^\]]+))?\]\]'
     def replace_image(match):
         filepath = match.group(1).strip()
         alt_text = match.group(2)
         filename = os.path.basename(filepath)
         alt = alt_text.strip() if alt_text else os.path.splitext(filename)[0]
         encoded_filename = urllib.parse.quote(filename)
         return f'![{alt}](/images/{encoded_filename})'
     return re.sub(pattern, replace_image, content)
 
 hugo_images = os.environ.get('HUGO_IMAGES', '/workspaces/hugo-blog/static/images')
 hugo_posts = os.environ.get('HUGO_POSTS', '/workspaces/hugo-blog/content/blog')
 
 compress_images(hugo_images)
 
 for md_file in Path(hugo_posts).glob('**/*.md'):
     content = md_file.read_text(encoding='utf-8')
     if '![[' in content:
         new_content = convert_obsidian_images(content)
         if content != new_content:
             md_file.write_text(new_content, encoding='utf-8')
             print(f"  ✅ Converted: {md_file.name}")
 
 print("Done.")
 PYTHON_SCRIPT
 
 echo "🏗️  Building Hugo site..."
 hugo
 echo "✅ Build complete."
 
 if [ "$DRY_RUN" = false ]; then
     echo ""
     echo "📋 Next steps:"
     echo "   git add . && git commit -m 'Update blog' && git push"
 fi
