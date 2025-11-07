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

# Image resizing options
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
# SORT YAML BY sortOrder
# ============================================================
sort_yaml_by_sortOrder() {
    echo "Tri de galerie_list.yaml selon sortOrder..."

    TMP_SORTED="$workpath/sorted_galerie.yaml"

    awk '
        BEGIN { block=""; order=0 }
        /^  - src:/ {
            if (block != "") print order "|" block;
            block=$0 "\n"; order=0; next
        }
        /sortOrder:/ {
            split($0, a, ":"); order=a[2]+0
        }
        { block = block $0 "\n" }
        END { if (block != "") print order "|" block }
    ' "$OUTPUT_FILE" 2>/dev/null \
        | sort -n -t '|' -k1,1 \
        | cut -d'|' -f2- \
        | { echo "images:"; cat; } \
        > "$TMP_SORTED"

    mv "$TMP_SORTED" "$OUTPUT_FILE"
}

# ============================================================
# IMAGE RESIZING AND NUMBERING
# ============================================================
resize_and_compress_images() {
    echo "Redimensionnement et compression des images..."
    last_number=$(cat "$LAST_NUMBER_FILE")

    for file in "$ORIGINAL_DIR"/*; do
        if [[ -f "$file" && $(file -b --mime-type "$file") =~ ^image/ ]]; then
            last_number=$((last_number + 1))
            echo "$last_number" > "$LAST_NUMBER_FILE"

            if [[ "$file" == *"_vendu"* ]]; then
                large_image="${last_number}b_vendu.webp"
                small_image="${last_number}s_vendu.webp"
            else
                large_image="${last_number}b.webp"
                small_image="${last_number}s.webp"
            fi

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
        fi
    done
}

# ============================================================
# GENERATE OR UPDATE YAML
# ============================================================
generate_image_list() {
    echo "Génération de galerie_list.yaml..."
    [ ! -f "$OUTPUT_FILE" ] && echo "images:" > "$OUTPUT_FILE"

    for image in $(ls $IMAGE_DIR/*b*.webp 2>/dev/null | sort -V); do
        base_name=$(basename "$image" .webp)

        # Status detection
        status="en_vente"
        [[ "$base_name" == *"_vendu"* ]] && status="vendu"

        # Extract number before 'b'
        clean_base="${base_name%_vendu}"
        image_number="${clean_base%%b*}"

        # Optional metadata
        price="x"; dimensions="x"; weight="x"
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

        # Append YAML block
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

# ============================================================
# EXECUTION
# ============================================================
start_time=$(date +%s)

sort_yaml_by_sortOrder       # reorder any manual edits
resize_and_compress_images
generate_image_list
sort_yaml_by_sortOrder       # reorder including new images

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
