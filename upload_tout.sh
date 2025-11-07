#!/bin/sh

#WICH_GITHUB####################################################
github_depo="remi-maurice/bronze.neocities.org"

# Directories###################################################
workpath="$HOME/bronze.neocities.org"

IMAGE_DIR="$workpath/website/img/gallerie"
ORIGINAL_DIR="$workpath/original"
OUTPUT_FILE="$workpath/website/galerie_list.yaml"
PROCESSED_FILE="$IMAGE_DIR/processed_images.txt"

#IMAGE_RESIZING_OPTIONS#########################################
large_image_size="1920x1080>"
large_image_quality="100"

small_image_size="300x>"
small_image_quality="100"

#HOT_MESS_BEGINS################################################
while [ -z "$commit_message" ]; do
  read -p "Message pour l'historique: " commit_message
done

################################################################################
# 1. Redimensionnement + compression des images
################################################################################

resize_and_compress_images() {
    echo ""
    echo "==================="
    echo "1) Traitement des nouvelles images"
    echo "==================="
    step1_start=$(date +%s)

    echo "→ Recherche du prochain numéro disponible..."
    max_number=$(ls -1 $IMAGE_DIR/*b.webp 2>/dev/null | awk -F '/' '{print $NF}' | awk -F 'b.webp' '{print $1}' | sort -nr | head -n1)
    max_number=${max_number:-0}
    next_number=$((max_number + 1))

    echo "→ Prochain numéro : $next_number"
    echo "→ Début du redimensionnement..."

    for file in "$ORIGINAL_DIR"/*; do
        if [[ -f "$file" && $(file -b --mime-type "$file") =~ ^image/ ]]; then
            
            echo "  • Traitement de: $(basename "$file")"

            if [[ "$file" == *"_vendu"* ]]; then
                large_image="${next_number}b_vendu.webp"
                small_image="${next_number}s_vendu.webp"
            else
                large_image="${next_number}b.webp"
                small_image="${next_number}s.webp"
            fi

            magick "$file" -auto-orient -resize "$large_image_size" -quality "$large_image_quality" -define webp:lossless=true \
                -define webp:auto-filter=true -define webp:filter-strength=0 -define webp:method=4 \
                -define webp:partition-limit=0 -define webp:sns-strength=0 "$IMAGE_DIR/$large_image"

            magick "$file" -auto-orient -resize "$small_image_size" -quality "$small_image_quality" -define webp:lossless=false \
                -define webp:auto-filter=true -define webp:filter-strength=25 -define webp:method=4 \
                -define webp:partition-limit=0 -define webp:sns-strength=0 "$IMAGE_DIR/$small_image"

            echo "    ✓ Créé : $large_image et $small_image"
            next_number=$((next_number + 1))
        fi
    done

    step1_end=$(date +%s)
    echo "→ Traitement terminé en $((step1_end - step1_start)) secondes"
}

################################################################################
# 2. Génération du YAML (avec ordre manuel)
################################################################################

generate_image_list() {
    echo ""
    echo "==================="
    echo "2) Génération du fichier YAML"
    echo "==================="
    step2_start=$(date +%s)

    declare -A existing_order
    max_existing_order=0

    echo "→ Lecture de l'ancien YAML pour récupérer les ordres..."
    if [ -f "$OUTPUT_FILE" ]; then
        current_src=""
        while IFS= read -r line; do
            if [[ $line =~ src:\ img/gallerie/([^[:space:]]+) ]]; then
                current_src="${BASHREMATCH[1]}"
            fi
            if [[ $line =~ order:\ ([0-9]+) ]]; then
                order_value="${BASHREMATCH[1]}"
                existing_order["$current_src"]="$order_value"
                if (( order_value > max_existing_order )); then
                    max_existing_order=$order_value
                fi
            fi
        done < "$OUTPUT_FILE"
        echo "→ Ordre maximum existant : $max_existing_order"
    else
        echo "→ Aucun fichier YAML existant."
    fi

    echo "→ Reconstruction du YAML..."
    tmpfile=$(mktemp)
    echo "images:" > "$tmpfile"
    printf "\n" >> "$tmpfile"

    for image in $(ls $IMAGE_DIR/*b*.webp | sort -V); do
        base_name=$(basename "$image" .webp)

        if [[ "$base_name" == *"_vendu"* ]]; then status="vendu"
        else status="en_vente"; fi

        clean_base_name="${base_name%_vendu}"
        image_number="${clean_base_name%%b*}"

        price="x"; dimensions="x"; weight="x"
        if [[ "$clean_base_name" == *"_"* ]]; then
            IFS='_' read -r -a parts <<< "$clean_base_name"
            price="${parts[1]}"; dimensions="${parts[2]}"; weight="${parts[3]}"
        fi

        description=""
        [[ "$price" != "x" ]] && description+="$price"€""
        [[ "$dimensions" != "x" ]] && description+="${description:+, }$dimensions"cm""
        [[ "$weight" != "x" ]] && description+="${description:+, }$weight"kg""

        key="${base_name}.webp"
        if [[ -n "${existing_order["$key"]}" ]]; then
            order_value="${existing_order["$key"]}"
        else
            order_value=$((max_existing_order + 1))
            max_existing_order=$order_value
            echo "  → Nouvelle image détectée : $base_name (order=$order_value)"
        fi

        {
            echo "  - src: img/gallerie/${base_name}.webp"
            echo "    srct: img/gallerie/${image_number}s.webp"
            echo "    title: \"$image_number:#$status\""
            echo "    numero: $image_number"
            echo "    order: $order_value"
            echo "    description: \"$description\""
            printf "\n"
        } >> "$tmpfile"
    done

    echo "→ Tri par ordre décroissant..."
    {
        echo "images:"
        printf "\n"
        awk -v RS= '/src:/ {
            match($0, /order:[[:space:]]*([0-9]+)/, m)
            print m[1] "|||" $0
        }' "$tmpfile" | sort -t '|' -k1,1nr | sed 's/^[0-9]*|||//'
    } > "$OUTPUT_FILE"

    rm "$tmpfile"

    step2_end=$(date +%s)
    echo "→ YAML généré en $((step2_end - step2_start)) secondes"
}


################################################################################
# 3. Nettoyage
################################################################################
echo ""
echo "==================="
echo "3) Nettoyage"
echo "==================="
step3_start=$(date +%s)

resize_and_compress_images
generate_image_list

echo "→ Suppression des originaux..."
find "$ORIGINAL_DIR" -type f ! -name ".gitkeep" -exec rm -f {} +

step3_end=$(date +%s)
echo "→ Nettoyage effectué en $((step3_end - step3_start)) secondes"


################################################################################
# 4. Git Push
################################################################################
echo ""
echo "==================="
echo "4) Envoi vers GitHub"
echo "==================="
step4_start=$(date +%s)

cd "$workpath"
git add .
git commit -m "$commit_message"
git push -u origin master

step4_end=$(date +%s)
echo "→ Envoi terminé en $((step4_end - step4_start)) secondes"


################################################################################
# 5. Suivi GitHub Actions
################################################################################
echo ""
echo "==================="
echo "5) Suivi des Actions GitHub"
echo "==================="

dots=0
max_dots=3
timeout=30
step5_start=$(date +%s)

while ((timeout > 0)); do
    latest_run_id=$(gh run list --repo "$github_depo" --status in_progress --limit 1 --json databaseId --jq '.[0].databaseId')

    if [ -n "$latest_run_id" ]; then
        echo "→ Workflow détecté : $latest_run_id"
        gh run watch "$latest_run_id"
        break
    else
        dot_str=$(printf "%${dots}s" | tr ' ' '.')
        printf "\rEn attente de GitHub Actions%s   " "$dot_str"
        sleep 0.1
        ((dots=dots<max_dots?dots+1:0))
        timeout=$((timeout - 1))
    fi
done

printf "\r\033[K"

step5_end=$(date +%s)
echo "→ Suivi terminé en $((step5_end - step5_start)) secondes"


################################################################################
# FINAL MESSAGE
################################################################################
echo ""
echo "============================================="
echo "✅ Mise à jour terminée"
echo "⏱️ Durée totale : $(( $(date +%s) - start_time )) secondes"
echo "============================================="
