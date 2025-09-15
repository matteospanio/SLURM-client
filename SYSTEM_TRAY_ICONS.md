# System Tray Icon Creation Guide

The SLURM Queue Client uses system tray icons for desktop integration. Currently, the icon files are placeholders.

## Creating Icons

You can create 16x16 or 32x32 PNG icons for the following states:

1. `tray_connected.png` - When connected to a SLURM cluster (green/blue theme)
2. `tray_disconnected.png` - When not connected (gray theme)  
3. `tray_alert.png` - When there are job alerts (red/orange theme)

## Using ImageMagick (if available)

```bash
# Create a simple colored square icon (16x16)
convert -size 16x16 xc:green assets/icons/tray_connected.png
convert -size 16x16 xc:gray assets/icons/tray_disconnected.png
convert -size 16x16 xc:orange assets/icons/tray_alert.png
```

## Using other tools

- GIMP: Create 16x16 or 32x32 PNG images
- Inkscape: Create SVG and export to PNG
- Online icon generators

## Fallback Behavior

If icons are missing or invalid, the system tray will:
1. Use system default icons
2. Still function for window management
3. Show debug messages in console

The application will continue to work without custom icons.