#!/bin/sh
# Hook to easily git push and neocities push
read -p "Message pour l'historique(obligatoire):" commit_message
#______________________________________________________________________________________
# Image processing

# Directories
BASE_DIR="$HOME/bronze.neocities.org/website"
IMAGE_DIR="$BASE_DIR/img/gallerie"
ORIGINAL_DIR="./original"
RESIZED_DIR="$IMAGE_DIR"
OUTPUT_FILE="$HOME/bronze.neocities.org/website/galerie_list.yaml"
NEOCITIES_PATH="$HOME/.local/share/gem/ruby/3.0.0/bin/neocities"
PROCESSED_FILE="$IMAGE_DIR/processed_images.txt"

# Function to resize and compress images
resize_and_compress_images() {
    echo "Redimensionnement et compression des images..."
    max_number=$(ls -1 $IMAGE_DIR/*b.webp 2>/dev/null | awk -F '/' '{print $NF}' | awk -F 'b.webp' '{print $1}' | sort -nr | head -n1)
    max_number=${max_number:-0} # Set to 0 if no image found
    next_number=$((max_number + 1))

    for file in "$ORIGINAL_DIR"/*; do
        if [[ -f "$file" && $(file -b --mime-type "$file") =~ ^image/ ]]; then
            large_image="${next_number}b.webp"
            small_image="${next_number}s.webp"

            magick "$file" -auto-orient -resize '1920x1080>' -quality 100 -define webp:lossless=true \
                -define webp:auto-filter=true -define webp:filter-strength=0 -define webp:method=4 \
                -define webp:partition-limit=0 -define webp:sns-strength=0 "$RESIZED_DIR/$large_image"


            magick "$file" -auto-orient -resize '300x>' -quality 75 -define webp:lossless=false \
                -define webp:auto-filter=true -define webp:filter-strength=25 -define webp:method=4 \
                -define webp:partition-limit=0 -define webp:sns-strength=0 "$RESIZED_DIR/$small_image"

            echo "$file converti en $large_image et $small_image"
            echo "$large_image" >> $PROCESSED_FILE
            echo "$small_image" >> $PROCESSED_FILE
            next_number=$((next_number + 1))
        fi
    done
}

# Function to generate galerie_list.yaml
generate_image_list() {
    echo "Génération de galerie_list.yaml..."
    echo "images:" > $OUTPUT_FILE

    for image in $(ls $IMAGE_DIR/*b.webp | sort -Vr); do
        base_name=$(basename "$image" b.webp)
        status="disponible"

        if [[ "$base_name" == *_vendu ]]; then
            status="vendu"
            base_name="${base_name%_vendu}" # Remove the _vendu part
        fi

        # Add status as a tag in the title
        echo "  - src: img/gallerie/${base_name}b.webp" >> $OUTPUT_FILE
        echo "    srct: img/gallerie/${base_name}s.webp" >> $OUTPUT_FILE
        echo "    title: \"$base_name #$status\"" >> $OUTPUT_FILE
        echo "    numero: $base_name" >> $OUTPUT_FILE
    done
}

# Start the timer
start_time=$(date +%s)

# Resize and compress images
resize_and_compress_images

# Generate galerie_list.yaml
generate_image_list

echo "Suppression des images originales..."
rm -f "$ORIGINAL_DIR"/*
rm -f $PROCESSED_FILE
#______________________________________________________________________________________
# Push to GitHub:
echo "______________________________________________"
echo "Envoi vers Github"
cd $HOME/bronze.neocities.org
git add .
git commit -m "$commit_message" 
git push -u origin master

# End the timer and calculate elapsed time
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

# Final message
echo "______________________________________________"
echo "MAJ du site terminée en $elapsed_time secondes !"
