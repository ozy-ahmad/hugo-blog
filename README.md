# Hugo Blog Sync

Sync Obsidian posts and images to Hugo, compress images, and open a pull request. GitHub Actions builds and checks it, Cloudflare Pages deploys a preview, and merging to `main` publishes it.

## Quick Start

```bash
./sync.sh
```

Preview changes without creating a branch, commit or PR:

```bash
./sync.sh --dry-run
```

## Workflow

```mermaid
flowchart LR
    O["Obsidian"] -->|sync.sh: rsync, compress, convert| BR["branch post/…"]
    BR -->|gh pr create| PR["Pull request"]
    PR -->|GitHub Actions| CI["build + link check"]
    PR -->|Cloudflare Git integration| PV["preview: branch.hugo-blog-ecd.pages.dev"]
    PR -->|merge| M["main"]
    M -->|Cloudflare Git integration| PROD["ahmadfakhrozy.com"]
```

`sync.sh` starts from a clean, up-to-date `main`, waits for the checks, prints the preview URL and asks before merging. Nothing is pushed to `main` directly.

## CI/CD

| Piece | What it does |
|---|---|
| `.github/workflows/blog.yml` | On every PR (and on pushes to `main`): builds with Hugo (version pinned in `HUGO_VERSION`) including drafts, then checks internal links offline with lychee. This is the required `build` check |
| Cloudflare Pages (Git integration) | Builds a preview for every branch (drafts shown) and deploys `main` to production |
| `.github/workflows/links.yml` | Every Monday 01:00 UTC: checks external links and opens a "Broken links report" issue if any fail |
| `renovate.json` | Renovate opens PRs on Saturday mornings (Asia/Kuala_Lumpur) for Hugo, the PaperMod submodule and GitHub Actions. Updates are listed on the Dependency Dashboard issue |
| Ruleset on `main` | A PR and a green `build` are required; no direct pushes, no bypass |

**Hugo version:** it is set in `blog.yml`, `links.yml`, `.devcontainer/Dockerfile` **and** in the Cloudflare Pages project (`HUGO_VERSION`, Production and Preview). On a Renovate Hugo PR, update Cloudflare before merging.

## Configuration

These can be set as environment variables or edited in `sync.sh`:

| Variable | Description | Default |
|----------|-------------|---------|
| `OBSIDIAN_POSTS` | Obsidian posts folder | `/home/ozy/Obsidian/SecondBrain/Posts` |
| `OBSIDIAN_ATTACHMENTS` | Obsidian images folder | `/home/ozy/Obsidian/SecondBrain/attachments` |
| `HUGO_POSTS` | Hugo posts destination | `/home/ozy/git/hugo-blog/content/blog` |
| `HUGO_IMAGES` | Hugo images destination | `/home/ozy/git/hugo-blog/static/images` |
| `MYREPO` | GitHub repository URL | `https://github.com/ozy-ahmad/hugo-blog` |

## Features

- ✅ Syncs posts from Obsidian to Hugo
- ✅ Copies only the images that posts reference, and compresses them (max 1200px, ~50% smaller)
- ✅ Converts `![[image.png]]` → `![image](/images/image.png)`
- ✅ Opens a PR; GitHub Actions builds, checks and Cloudflare deploys a preview
- ✅ Waits for CI, shows the preview, and asks before merging
- ✅ Dry-run mode for previewing changes

## Requirements

- git, rsync, python3, gh (logged in: `gh auth login`)
- python-pillow (auto-installed via pacman)

## Theme Management

This site uses [PaperMod](https://github.com/adityatelange/hugo-PaperMod/) theme as a git submodule.

```bash
# Check current theme version
cd themes/PaperMod && git log -1 --oneline

# Renovate opens a PR for theme updates. To update by hand instead:
git submodule update --remote themes/PaperMod

# After updating, check custom layouts for compatibility
# See layouts/README.md for customizations
```

> **Note:** Custom layouts in `layouts/` override theme defaults. After updating the theme, compare your customizations with the new theme files.

