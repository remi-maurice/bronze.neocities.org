#!/bin/bash
input_folder="./original/"
output_folder="./resized"

mkdir -p "$input_folder"
mkdir -p "$output_folder"

for file in "$input_folder"/*; do
    if [[ -f "$file" && $(file -b --mime-type "$file") =~ ^image/ ]]; then
        filename=$(basename "$file")

        # Resize and compress for large images
        magick "$file" -auto-orient -resize '1920x1080>' -quality 75 -define webp:lossless=false -define webp:auto-filter=true -define webp:filter-strength=25 -define webp:method=4 -define webp:partition-limit=0 -define webp:sns-strength=0 "$output_folder"/"${filename%.*}"b.webp

        # Resize and compress for small images
        magick "$file" -auto-orient -resize '300x>' -quality 75 -define webp:lossless=false -define webp:auto-filter=true -define webp:filter-strength=25 -define webp:method=4 -define webp:partition-limit=0 -define webp:sns-strength=0  "$output_folder"/"${filename%.*}"s.webp

        echo "$file converted"

    fi
done

echo "Conversion fini (ou pas d'images dans "original""
echo " Press 'q' to quit."
while true; do
    read -n 1 -r key
    if [ "$key" = 'q' ]; then
        break
    fi
done
