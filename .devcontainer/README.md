 # DevContainer Setup for Hugo Blog
 
 This devcontainer provides a complete Hugo development environment with Obsidian sync capabilities.
 
 ## Prerequisites
 
 - [DevPod](https://devpod.sh/docs/getting-started/install) installed
 - Docker running on your machine
 - Git credentials configured (SSH key or HTTPS)
 
 ## Quick Start (Local PC)
 
 ### Option 1: Using DevPod CLI
 
 ```bash
 # Navigate to project
 cd /home/ozy/git/hugo-blog
 
 # Start devcontainer
 devpod up .
 
 # Open shell in container
 devpod ssh hugo-blog
 ```
 
 ### Option 2: Using DevPod Desktop App
 
 1. Open DevPod app
 2. Click **"+ Create"**
 3. Select **"Local"** provider
 4. Enter path: `/home/ozy/git/hugo-blog`
 5. Click **"Create Workspace"**
 
 ### Option 3: Using VS Code
 
 1. Install **"Dev Containers"** extension
 2. Open `/home/ozy/git/hugo-blog` in VS Code
 3. Press `Ctrl+Shift+P` → **"Dev Containers: Reopen in Container"**
 
 ## Usage Inside Container
 
 ### Start Hugo Dev Server
 
 ```bash
 hugo server -D
 ```
 
 Access at: http://localhost:1313
 
 ### Sync from Obsidian
 
 ```bash
 # Sync posts and images from Obsidian, compress images, build site
 ./.devcontainer/sync-container.sh
 
 # Dry run (preview without changes)
 ./.devcontainer/sync-container.sh --dry-run
 ```
 
 ### Build Site
 
 ```bash
 hugo
 ```
 
 ### Commit and Push
 
 ```bash
 git add .
 git commit -m "Update blog"
 git push
 ```
 
 ## Mounted Directories
 
 | Host Path | Container Path | Purpose |
 |-----------|----------------|---------|
 | `~/Obsidian/SecondBrain/Posts` | `/obsidian/Posts` | Blog posts source |
 | `~/Obsidian/SecondBrain/attachments` | `/obsidian/attachments` | Images source |
 | Project folder | `/workspaces/hugo-blog` | Hugo site |
 
 ## Environment Variables
 
 Set automatically in container:
 
 | Variable | Value |
 |----------|-------|
 | `OBSIDIAN_POSTS` | `/obsidian/Posts` |
 | `OBSIDIAN_ATTACHMENTS` | `/obsidian/attachments` |
 | `HUGO_POSTS` | `/workspaces/hugo-blog/content/blog` |
 | `HUGO_IMAGES` | `/workspaces/hugo-blog/static/images` |
 
 ## Included Tools
 
 | Tool | Version | Purpose |
 |------|---------|---------|
 | Hugo Extended | 0.140.1 | Static site generator |
 | Python 3 | Latest | Image processing |
 | Pillow | Latest | Image compression |
 | Git | Latest | Version control |
 | GitHub CLI | Latest | GitHub operations |
 | rsync | Latest | File sync |
 
 ## Workflow
 
 ```
 1. Write posts in Obsidian (~/Obsidian/SecondBrain/Posts/)
 2. Add images to attachments folder
 3. Open devcontainer
 4. Run sync script: ./.devcontainer/sync-container.sh
 5. Preview: hugo server -D
 6. Commit and push
 ```
 
 ## Troubleshooting
 
 ### Container Won't Start
 
 ```bash
 # Check Docker is running
 docker ps
 
 # Rebuild container
 devpod up . --recreate
 ```
 
 ### Obsidian Folders Not Mounted
 
 Verify paths exist on host:
 ```bash
 ls ~/Obsidian/SecondBrain/Posts
 ls ~/Obsidian/SecondBrain/attachments
 ```
 
 ### Git Credentials Not Working
 
 ```bash
 # Check git config
 git config --global user.name
 git config --global user.email
 
 # Test SSH
 ssh -T git@github.com
 
 # Test GitHub CLI
 gh auth status
 ```
 
 ### Hugo Theme Missing
 
 ```bash
 git submodule update --init --recursive
 ```
 
 ## Remote Development (MacBook → PC)
 
 To use this devcontainer remotely:
 
 1. Ensure Tailscale is connected on both devices
 2. On PC, ensure SSH and Docker are running
 3. From MacBook:
 
 ```bash
 # Add PC as DevPod provider (one-time)
 devpod provider add ssh --name my-pc --host ozy@<pc-ip-or-tailscale-hostname>
 
 # Start workspace on remote PC
 devpod up git@github.com:ozy-ahmad/hugo-blog --provider my-pc
 ```
 
 Note: Remote containers use the PC's Git credentials, not MacBook's.
