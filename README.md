# Hugo Blog Sync

Sync Obsidian posts and images to Hugo, compress images, and deploy to GitHub.

## Quick Start

```bash
./sync.sh
```

## Configuration

Edit these variables in `sync.sh`:

| Variable | Description | Default |
|----------|-------------|---------|
| `OBSIDIAN_POSTS` | Obsidian posts folder | `/home/ozy/Obsidian/SecondBrain/Posts` |
| `OBSIDIAN_ATTACHMENTS` | Obsidian images folder | `/home/ozy/Obsidian/SecondBrain/attachments` |
| `HUGO_POSTS` | Hugo posts destination | `/home/ozy/git/hugo-blog/content/posts` |
| `HUGO_IMAGES` | Hugo images destination | `/home/ozy/git/hugo-blog/static/images` |
| `MYREPO` | GitHub repository URL | `https://github.com/ozy-ahmad/hugo-blog` |
| `BRANCH` | Git branch to push | `main` |

## Features

- ✅ Syncs posts from Obsidian to Hugo
- ✅ Syncs and compresses images (max 1200px, ~50% smaller)
- ✅ Converts `![[image.png]]` → `![image](/images/image.png)`
- ✅ Builds Hugo site
- ✅ Commits and pushes to GitHub

## Requirements

- git, rsync, python3, hugo
- python-pillow (auto-installed via pacman)
