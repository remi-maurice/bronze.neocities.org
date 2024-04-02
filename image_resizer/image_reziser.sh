#!/bin/bash
 
# Utility script to resize and compress images to a thumbnail and "big" image.

input_folder="./original/"
output_folder="./resized"

mkdir -p "$input_folder"
mkdir -p "$output_folder"

for file in "$input_folder"/*; do
    if [[ -f "$file" && $(file -b --mime-type "$file") =~ ^image/ ]]; then
        filename=$(basename "$file")
        
        # Resize and compress for large images
        magick "$file" -auto-orient -resize '1920x1080>' -quality 50 -define webp:lossless=false -define webp:auto-filter=true -define webp:filter-strength=50 -define webp:method=6 -define webp:partition-limit=0 -define webp:sns-strength=80 -define webp:thread-level=1 "$output_folder"/"${filename%.*}"b.webp
        
        # Resize and compress for small images
        magick "$file" -auto-orient -resize '300x>' -quality 50 -define webp:lossless=false -define webp:auto-filter=true -define webp:filter-strength=50 -define webp:method=6 -define webp:partition-limit=0 -define webp:sns-strength=80 -define webp:thread-level=1 "$output_folder"/"${filename%.*}"s.webp

        echo "$file converted"

    fi
done
