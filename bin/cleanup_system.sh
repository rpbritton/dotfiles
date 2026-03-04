#!/bin/bash

# Clean up screenshots
find ~/Pictures/Screenshots -mtime +30 -exec trash-put {} +

# Clean snap trash
find ~/snap/ -type d -path "*/.local/share/Trash" -exec trash-empty 30 --trash-dir={} \;

# Empty system trash
trash-empty 30

