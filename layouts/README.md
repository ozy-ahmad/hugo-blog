# Custom Layouts

This directory contains custom layouts that override the PaperMod theme defaults.

## Layout Overrides

| File | Purpose |
|------|---------|
| `index.html` | Custom homepage with centered profile image + recent posts section |
| `partials/header.html` | Added mobile hamburger menu for responsive navigation |
| `partials/footer.html` | Simplified footer with dynamic copyright year only |
| `partials/search-modal.html` | Custom search modal with Fuse.js integration |
| `_default/baseof.html` | Base template for all pages |

## Important Notes

When upgrading PaperMod, check if these overrides need updates:

```bash
# Compare your customizations with theme defaults
diff layouts/partials/header.html themes/PaperMod/layouts/partials/header.html
diff layouts/partials/footer.html themes/PaperMod/layouts/partials/footer.html
```

## Key Customizations

### Homepage (`index.html`)
- Profile image is centered with `text-align: center` and flexbox
- Shows recent posts below the profile section
- Uses `profileMode.recentLimit` config (defaults to 5)

### Header (`partials/header.html`)
- Added hamburger menu button (`.menu-toggle`)
- Mobile menu slides in as a sidebar
- Includes JavaScript for toggle behavior

### Footer (`partials/footer.html`)
- Removed "Powered by Hugo & PaperMod" attribution
- Dynamic copyright: `© {current_year} Ahmad Fakhrozy`
