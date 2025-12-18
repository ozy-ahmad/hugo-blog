# Hugo Blog Sync

Sync Obsidian posts and images to Hugo, then deploy to GitHub.

## Usage

```bash
./sync.sh
```

## What It Does

```mermaid
flowchart LR
    A[Obsidian Posts] -->|rsync| B[Hugo Posts]
    C[Obsidian Attachments] -->|rsync| D[Hugo Images]
    B --> E[Convert Image Links]
    D --> E
    E --> F[Hugo Build]
    F --> G[Git Push Main]
```

## Configuration

| Setting | Path |
|---------|------|
| Obsidian Posts | `/home/ozy/Obsidian/SecondBrain/Posts` |
| Obsidian Attachments | `/home/ozy/Obsidian/SecondBrain/attachments` |
| Hugo Posts | `content/posts` |
| Hugo Images | `static/images` |

## Image Conversion

The script automatically converts Obsidian image syntax to Hugo format:

| Obsidian | Hugo |
|----------|------|
| `![[photo.png]]` | `![photo](/images/photo.png)` |
| `![[photo.png\|My Photo]]` | `![My Photo](/images/photo.png)` |
