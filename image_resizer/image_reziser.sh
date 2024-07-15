#!/bin/bash

# Utility script to resize and compress images to a thumbnail and "big" image.

input_folder="./original/"
output_folder="./resized"

# Create directories if they don't exist
mkdir -p "$input_folder"
mkdir -p "$output_folder"

# Function to process images
process_images() {
    local auto_adjust=$1
    for file in "$input_folder"/*; do
        if [[ -f "$file" && $(file -b --mime-type "$file") =~ ^image/ ]]; then
            filename=$(basename "$file")
            
            # Prepare the common options for the `magick` command
            # common_options="-auto-orient -quality 50 -define webp:lossless=false -define webp:auto-filter=true -define webp:filter-strength=50 -define webp:method=6 -define webp:partition-limit=0 -define webp:sns-strength=80 -define webp:thread-level=1"
            
            common_options="-auto-orient -quality 40 -define webp:lossless=false -define webp:auto-filter=false -define webp:method=4 -define webp:thread-level=4"


            # Add auto-adjust options if requested
            if [[ "$auto_adjust" == true ]]; then
                common_options="$common_options -auto-level -auto-gamma"
            fi

            # Resize and compress for large images
            magick "$file" $common_options -resize '1920x1080>' "$output_folder"/"${filename%.*}"b.webp

            # Resize and compress for small images
            magick "$file" $common_options -resize '300x>' "$output_folder"/"${filename%.*}"s.webp

            echo "$file converted"
        else
            echo "$file is not a valid image file, skipping."
        fi
    done
}

# Function to prompt for auto-adjust option
prompt_auto_adjust() {
    while true; do
        read -p "Do you want to auto adjust level and gamma? (y/n): " yn
        case "$yn" in
            [Yy]* )
                echo "Processing images with auto adjust."
                process_images true
                
                break
                ;;
            [Nn]* )
                echo "Processing images without auto adjust."
                process_images false
                break
                ;;
            * )
                echo "Invalid input. Please answer yes (y) or no (n)."
                ;;
        esac
    done
}

# Check if the required 'magick' command is available
if ! command -v magick &> /dev/null; then
    echo "ImageMagick is not installed. Please install it and try again."
    exit 1
fi

# Start the processing
prompt_auto_adjust
