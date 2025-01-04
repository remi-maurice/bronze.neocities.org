#!/bin/sh
# This script automates git pushes, neocities updates, and image processing for the gallery.

read -p "Message pour l'historique (obligatoire) : " commit_message

# Directories
IMAGE_DIR="./website/img/gallerie"
ORIGINAL_DIR="./original"
OUTPUT_FILE="./website/galerie_list.yaml"
PROCESSED_FILE="./website/img/gallerie/processed_images.txt"

# Function to resize and compress images
resize_and_compress_images() {
    echo "Redimensionnement et compression des images..."
    max_number=$(ls -1 $IMAGE_DIR/*b.webp 2>/dev/null | awk -F '/' '{print $NF}' | awk -F 'b.webp' '{print $1}' | sort -nr | head -n1)
    max_number=${max_number:-0} # Set to 0 if no image found
    next_number=$((max_number + 1))

    for file in "$ORIGINAL_DIR"/*; do
        if [[ -f "$file" && $(file -b --mime-type "$file") =~ ^image/ ]]; then
            tags=$(basename "$file" | grep -oP '_[^.]+(?=\.)' | tr '_' ',')
            tag_suffix=$(echo "$tags" | sed 's/,/_/g')

            if [[ -n "$tag_suffix" ]]; then
                large_image="${next_number}b_${tag_suffix}.webp"
                small_image="${next_number}s_${tag_suffix}.webp"
            else
                large_image="${next_number}b.webp"
                small_image="${next_number}s.webp"
            fi

            magick "$file" -auto-orient -resize '1920x1080>' -quality 100 -define webp:lossless=true \
                -define webp:auto-filter=true -define webp:filter-strength=0 -define webp:method=4 \
                -define webp:partition-limit=0 -define webp:sns-strength=0 "$IMAGE_DIR/$large_image"

            magick "$file" -auto-orient -resize '300x>' -quality 75 -define webp:lossless=false \
                -define webp:auto-filter=true -define webp:filter-strength=25 -define webp:method=4 \
                -define webp:partition-limit=0 -define webp:sns-strength=0 "$IMAGE_DIR/$small_image"

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

    for image in $(ls $IMAGE_DIR/*b*.webp | sort -Vr); do
        base_name=$(basename "$image" .webp)
        tags=$(echo "$base_name" | grep -oP '_[^b]+(?=b)' | tr '_' ',' | sed 's/^,//')
        clean_base_name="${base_name%b}"
        image_number=$(echo "$clean_base_name" | sed 's/_[^_]*$//')

        if [[ -n "$tags" ]]; then
            tag_list="#$(echo "$tags" | tr ',' ' #')"
        else
            tag_list="en_vente"
        fi

        echo "  - src: img/gallerie/${base_name}.webp" >> $OUTPUT_FILE
        echo "    srct: img/gallerie/${image_number}s.webp" >> $OUTPUT_FILE
        echo "    title: \"$image_number: $tag_list\"" >> $OUTPUT_FILE
        echo "    numero: $image_number" >> $OUTPUT_FILE
    done
}

# Start the timer
start_time=$(date +%s)

# Resize and compress images
resize_and_compress_images

# Generate galerie_list.yaml
generate_image_list

# Clean up original images
echo "Suppression des images originales..."
find "$ORIGINAL_DIR" -type f ! -name ".gitkeep" -exec rm -f {} +
rm -f $PROCESSED_FILE

# Push to GitHub
echo "______________________________________________"
echo "Envoi vers GitHub"
cd $HOME/bronze.neocities.org
git add .
git commit -m "$commit_message"
git push -u origin master

# Monitor GitHub Actions
echo "______________________________________________"
echo "Suivi des Actions GitHub en cours..."
timeout=30
while ((timeout > 0)); do
    latest_run_id=$(gh run list --repo remi-maurice/bronze.neocities.org --status in_progress --limit 1 --json databaseId --jq '.[0].databaseId')

    if [ -n "$latest_run_id" ]; then
        gh run watch "$latest_run_id"
        break
    else
        echo "Aucun workflow détecté. Nouvelle tentative dans 1 secondes..."
        sleep 1
        timeout=$((timeout - 1))
    fi
done

# End the timer and calculate elapsed time
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

# Final message
echo "______________________________________________"
echo "MAJ terminée en $elapsed_time secondes !"
