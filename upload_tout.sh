#!/bin/sh

# WICH_GITHUB ####################################################
github_depo="remi-maurice/bronze.neocities.org"

# Directories ###################################################
workpath="$HOME/bronze.neocities.org"

IMAGE_DIR="$workpath/website/img/gallerie"
ORIGINAL_DIR="$workpath/original"
OUTPUT_FILE="$workpath/website/galerie_list.yaml"
PROCESSED_FILE="$IMAGE_DIR/processed_images.txt"
LAST_NUMBER_FILE="$workpath/last_number.txt"

# IMAGE_RESIZING_OPTIONS #########################################
large_image_size="1920x1080>"
large_image_quality="100"

small_image_size="300x>"
small_image_quality="100"

# Ensure last_number.txt exists #################################
if [ ! -f "$LAST_NUMBER_FILE" ]; then
    echo "0" > "$LAST_NUMBER_FILE"
fi

# Ask for commit message ########################################
while [ -z "$commit_message" ]; do
  read -p "Message pour l'historique: " commit_message
done


############################################################
# IMAGE RESIZING + NUMBERING (Solution A)
############################################################
resize_and_compress_images() {
    echo "Redimensionnement et compression des images..."

    # Load last used number
    last_number=$(cat "$LAST_NUMBER_FILE")

    for file in "$ORIGINAL_DIR"/*; do
        if [[ -f "$file" && $(file -b --mime-type "$file") =~ ^image/ ]]; then

            # Increment and save new number
            last_number=$((last_number + 1))
            echo "$last_number" > "$LAST_NUMBER_FILE"

            if [[ "$file" == *"_vendu"* ]]; then
                large_image="${last_number}b_vendu.webp"
                small_image="${last_number}s_vendu.webp"
            else
                large_image="${last_number}b.webp"
                small_image="${last_number}s.webp"
            fi

            # Large version
            magick "$file" -auto-orient -resize "$large_image_size" -quality "$large_image_quality" \
                -define webp:lossless=true -define webp:auto-filter=true \
                -define webp:filter-strength=0 -define webp:method=4 \
                -define webp:partition-limit=0 -define webp:sns-strength=0 \
                "$IMAGE_DIR/$large_image"

            # Small version
            magick "$file" -auto-orient -resize "$small_image_size" -quality "$small_image_quality" \
                -define webp:lossless=false -define webp:auto-filter=true \
                -define webp:filter-strength=25 -define webp:method=4 \
                -define webp:partition-limit=0 -define webp:sns-strength=0 \
                "$IMAGE_DIR/$small_image"

            echo "$file converti en $large_image et $small_image"
            echo "$large_image" >> $PROCESSED_FILE
            echo "$small_image" >> $PROCESSED_FILE
        fi
    done
}


############################################################
# YAML GENERATION — SORT ORDER + BLANK LINES (Solution B)
############################################################
generate_image_list() {
    echo "Génération de galerie_list.yaml..."

    # Reset YAML
    echo "images:" > "$OUTPUT_FILE"

    # Sort numerically based on image number at the start
    for image in $(ls $IMAGE_DIR/*b*.webp 2>/dev/null | sort -V); do
        base_name=$(basename "$image" .webp)

        # Detect status
        if [[ "$base_name" == *"_vendu"* ]]; then
            status="vendu"
        else
            status="en_vente"
        fi

        # Extract number before "b"
        clean_base="${base_name%_vendu}"
        image_number="${clean_base%%b*}"

        # Parse optional metadata (price, dimensions, weight)
        price="x"
        dimensions="x"
        weight="x"

        if [[ "$clean_base" == *"_"* ]]; then
            IFS='_' read -r -a parts <<< "$clean_base"
            price="${parts[1]}"
            dimensions="${parts[2]}"
            weight="${parts[3]}"
        fi

        # Build description
        description=""
        [[ "$price" != "x" ]] && description+="${price}€"
        [[ "$dimensions" != "x" ]] && description+="${description:+, }${dimensions}cm"
        [[ "$weight" != "x" ]] && description+="${description:+, }${weight}kg"

        # YAML BLOCK (with blank line)
        {
            echo ""
            echo "  - src: img/gallerie/${base_name}.webp"
            echo "    srct: img/gallerie/${image_number}s.webp"
            echo "    title: \"$image_number:#$status\""
            echo "    numero: $image_number"
            echo "    sortOrder: $image_number"
            echo "    description: \"$description\""
        } >> "$OUTPUT_FILE"
    done
}


############################################################
# EXECUTION
############################################################
start_time=$(date +%s)

resize_and_compress_images
generate_image_list

echo "Suppression des images originales..."
find "$ORIGINAL_DIR" -type f ! -name ".gitkeep" -exec rm -f {} +
rm -f $PROCESSED_FILE


############################################################
# PUSH TO GITHUB
############################################################
echo "______________________________________________"
echo "Envoi vers Github"
cd "$workpath"
git add .
git commit -m "$commit_message"
git push -u origin master

############################################################
# GitHub Actions Watch
############################################################
echo "______________________________________________"
echo "Suivi des Actions GitHub en cours..."
timeout=30
while ((timeout > 0)); do
    latest_run_id=$(gh run list --repo "$github_depo" --status in_progress --limit 1 --json databaseId --jq '.[0].databaseId')

    if [ -n "$latest_run_id" ]; then
        gh run watch "$latest_run_id"
        break
    else
        echo "Aucun workflow détecté. Nouvelle tentative dans 1 secondes..."
        sleep 1
        timeout=$((timeout - 1))
    fi
done

# End timer
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

echo "______________________________________________"
echo "MAJ terminée en $elapsed_time secondes !"
