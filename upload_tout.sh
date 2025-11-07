#!/bin/sh

# ============================================================
# CONFIGURATION
# ============================================================
github_depo="remi-maurice/bronze.neocities.org"

workpath="$HOME/bronze.neocities.org"
IMAGE_DIR="$workpath/website/img/gallerie"
ORIGINAL_DIR="$workpath/original"
OUTPUT_FILE="$workpath/website/galerie_list.yaml"
PROCESSED_FILE="$IMAGE_DIR/processed_images.txt"
LAST_NUMBER_FILE="$workpath/last_number.txt"

# IMAGE RESIZING OPTIONS
large_image_size="1920x1080>"
large_image_quality="100"
small_image_size="300x>"
small_image_quality="100"

# Ensure last_number.txt exists
[ ! -f "$LAST_NUMBER_FILE" ] && echo "0" > "$LAST_NUMBER_FILE"

# ============================================================
# PROMPT FOR GIT COMMIT MESSAGE
# ============================================================
while [ -z "$commit_message" ]; do
  read -p "Message pour l'historique: " commit_message
done

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Load existing YAML into a temporary array of blocks
load_existing_yaml() {
    EXISTING_BLOCKS=""
    if [ -f "$OUTPUT_FILE" ]; then
        # Split blocks by '- src:'
        awk 'BEGIN{RS="  - src:"; ORS=""} NR>1{print "  - src:"$0"\n"}' "$OUTPUT_FILE"
    fi
}

# ============================================================
# IMAGE RESIZING AND NUMBERING
# ============================================================
resize_and_number_new_images() {
    echo "Redimensionnement et compression des nouvelles images..."
    last_number=$(cat "$LAST_NUMBER_FILE")
    
    NEW_BLOCKS=""
    
    for file in "$ORIGINAL_DIR"/*; do
        if [[ -f "$file" && $(file -b --mime-type "$file") =~ ^image/ ]]; then
            last_number=$((last_number + 1))
            echo "$last_number" > "$LAST_NUMBER_FILE"

            # Determine filenames
            if [[ "$file" == *"_vendu"* ]]; then
                large_image="${last_number}b_vendu.webp"
                small_image="${last_number}s_vendu.webp"
            else
                large_image="${last_number}b.webp"
                small_image="${last_number}s.webp"
            fi

            # Resize images
            magick "$file" -auto-orient -resize "$large_image_size" -quality "$large_image_quality" \
                -define webp:lossless=true -define webp:auto-filter=true \
                -define webp:filter-strength=0 -define webp:method=4 \
                -define webp:partition-limit=0 -define webp:sns-strength=0 \
                "$IMAGE_DIR/$large_image"

            magick "$file" -auto-orient -resize "$small_image_size" -quality "$small_image_quality" \
                -define webp:lossless=false -define webp:auto-filter=true \
                -define webp:filter-strength=25 -define webp:method=4 \
                -define webp:partition-limit=0 -define webp:sns-strength=0 \
                "$IMAGE_DIR/$small_image"

            echo "$file converti en $large_image et $small_image"
            echo "$large_image" >> $PROCESSED_FILE
            echo "$small_image" >> $PROCESSED_FILE

            # Determine metadata
            base_name=$(basename "$large_image" .webp)
            status="en_vente"
            [[ "$base_name" == *"_vendu"* ]] && status="vendu"
            
            clean_base="${base_name%_vendu}"
            image_number="$last_number"

            price="x"; dimensions="x"; weight="x"
            if [[ "$clean_base" == *"_"* ]]; then
                IFS='_' read -r -a parts <<< "$clean_base"
                price="${parts[1]}"
                dimensions="${parts[2]}"
                weight="${parts[3]}"
            fi

            description=""
            [[ "$price" != "x" ]] && description+="${price}€"
            [[ "$dimensions" != "x" ]] && description+="${description:+, }${dimensions}cm"
            [[ "$weight" != "x" ]] && description+="${description:+, }${weight}kg"

            # Build YAML block
            NEW_BLOCKS="${NEW_BLOCKS}
  - src: img/gallerie/${large_image}.webp
    srct: img/gallerie/${small_image}.webp
    title: \"$image_number:#$status\"
    numero: $image_number
    sortOrder: $image_number
    description: \"$description\""
        fi
    done

    echo "$NEW_BLOCKS"
}

# ============================================================
# GENERATE FINAL YAML
# ============================================================
generate_final_yaml() {
    NEW_BLOCKS=$(resize_and_number_new_images)
    
    echo "Génération finale de galerie_list.yaml..."

    # Load existing blocks
    EXISTING_BLOCKS=$(load_existing_yaml)

    # Combine: new blocks first, then existing blocks that are not duplicates
    FINAL_BLOCKS="$NEW_BLOCKS"
    if [ -n "$EXISTING_BLOCKS" ]; then
        while read -r block; do
            # Extract src filename
            src_line=$(echo "$block" | grep "src:" | awk '{print $2}')
            # Only add if not already in NEW_BLOCKS
            if ! echo "$NEW_BLOCKS" | grep -q "$src_line"; then
                FINAL_BLOCKS="${FINAL_BLOCKS}
$block"
            fi
        done <<< "$EXISTING_BLOCKS"
    fi

    # Write YAML header
    echo "images:" > "$OUTPUT_FILE"

    # Sort final blocks descending by sortOrder
    echo "$FINAL_BLOCKS" | awk '
        BEGIN { RS=""; FS="\n"; OFS="\n" }
        {
            for(i=1;i<=NF;i++){
                if($i ~ /sortOrder:/) { split($i,a,":"); order=a[2]+0 }
            }
            print order "|" $0
        }' \
    | sort -nr -t '|' -k1,1 \
    | cut -d'|' -f2- \
    >> "$OUTPUT_FILE"
}

# ============================================================
# EXECUTION
# ============================================================
start_time=$(date +%s)

generate_final_yaml

# Cleanup originals
echo "Suppression des images originales..."
find "$ORIGINAL_DIR" -type f ! -name ".gitkeep" -exec rm -f {} +
rm -f $PROCESSED_FILE

# ============================================================
# PUSH TO GITHUB
# ============================================================
echo "______________________________________________"
echo "Envoi vers Github"
cd "$workpath"
git add .
git commit -m "$commit_message"
git push -u origin master

# ============================================================
# WATCH GITHUB ACTIONS
# ============================================================
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

# ============================================================
# END TIMER
# ============================================================
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "______________________________________________"
echo "MAJ terminée en $elapsed_time secondes !"
