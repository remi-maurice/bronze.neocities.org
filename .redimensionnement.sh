#!/bin/bash

mkdir -p large

for img in original/*.{jpg,jpeg,png,webp,JPG,JPEG,PNG,WEBP}; do
    [ -f "$img" ] || continue

    echo "Processing: $img"

    magick "$img" \
        -auto-orient \
        -resize 1920x1080 \
        -quality 100 \
        -define webp:lossless=true \
        -define webp:auto-filter=true \
        -define webp:filter-strength=0 \
        -define webp:method=4 \
        -define webp:partition-limit=0 \
        -define webp:sns-strength=0 \
        "large/$(basename "${img%.*}").webp"
done