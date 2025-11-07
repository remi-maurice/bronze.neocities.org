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


resize_and_compress_images() {
    echo "Redimensionnement et compression des images..."
    max_number=$(ls -1 $IMAGE_DIR/*b.webp 2>/dev/null | awk -F '/' '{print $NF}' | awk -F 'b.webp' '{print $1}' | sort -nr | head -n1)
    max_number=${max_number:-0}
    next_number=$((max_number + 1))

    for file in "$ORIGINAL_DIR"/*; do
        if [[ -f "$file" && $(file -b --mime-type "$file") =~ ^image/ ]]; then
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

            echo "$file converti en $large_image et $small_image"
            echo "$large_image" >> $PROCESSED_FILE
            echo "$small_image" >> $PROCESSED_FILE
            next_number=$((next_number + 1))
        fi
    done
}

# Processing of the image filenames to create a .yaml file that is then used by nanogallery #
generate_image_list() {
    echo "Génération de galerie_list.yaml..."
    echo "images:" > $OUTPUT_FILE
    printf "\n" >> $OUTPUT_FILE

    for image in $(ls $IMAGE_DIR/*b*.webp | sort -Vr); do
        base_name=$(basename "$image" .webp)

        # Si le fichier a _vendu dans le titre 
        if [[ "$base_name" == *"_vendu"* ]]; then
            status="vendu"
        else
            status="en_vente"
        fi

        # Nettoyer le nom de base pour extraire le numéro principal sans 'b' ni autres caractères
        clean_base_name="${base_name%_vendu}"
        image_number="${clean_base_name%%b*}"  # Extraire le numéro avant 'b'

        # Variables par défaut
        price="x"
        dimensions="x"
        weight="x"

        # Extraire les informations à partir du nom du fichier
        if [[ "$clean_base_name" == *"_"* ]]; then
            IFS='_' read -r -a parts <<< "$clean_base_name"
            price="${parts[1]}"
            dimensions="${parts[2]}"
            weight="${parts[3]}"
        fi

        # Construire la description
        description=""
        [[ "$price" != "x" ]] && description+="$price"€""
        [[ "$dimensions" != "x" ]] && description+="${description:+, }$dimensions"cm""
        [[ "$weight" != "x" ]] && description+="${description:+, }$weight"kg""

        # Écrire dans le fichier YAML
        echo "  - src: img/gallerie/${base_name}.webp" >> $OUTPUT_FILE
        echo "    srct: img/gallerie/${image_number}s.webp" >> $OUTPUT_FILE
        echo "    title: \"$image_number:#$status\"" >> $OUTPUT_FILE
        echo "    numero: $image_number" >> $OUTPUT_FILE
        echo "    description: \"$description\"" >> $OUTPUT_FILE
        printf "\n" >> $OUTPUT_FILE
    done
}

# Execution #####################################################################
start_time=$(date +%s)

resize_and_compress_images

generate_image_list

echo "Suppression des images originales..."
find "$ORIGINAL_DIR" -type f ! -name ".gitkeep" -exec rm -f {} +
rm -f $PROCESSED_FILE

# Push vers GitHub ##############################################################
echo "______________________________________________"
echo "Envoi vers Github"
cd "$workpath"
git add .
git commit -m "$commit_message" 
git push -u origin master

# Suivi des GitHub Actions avec animated dots only
echo "______________________________________________"
echo "Suivi des Actions GitHub en cours..."

dots=0
max_dots=3
timeout=30

while ((timeout > 0)); do
    latest_run_id=$(gh run list --repo "$github_depo" --status in_progress --limit 1 --json databaseId --jq '.[0].databaseId')

    if [ -n "$latest_run_id" ]; then
        gh run watch "$latest_run_id"
        break
    else
        # Animated dots
        dot_str=$(printf "%${dots}s" | tr ' ' '.')
        printf "\rEn attente de Github Actions%s   " "$dot_str"
        sleep 0.5
        ((dots=dots<max_dots?dots+1:0))
        timeout=$((timeout - 1))
    fi
done

# Clear line after done
printf "\r\033[K"



# End the timer and calculate elapsed time
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

# Final message
echo "______________________________________________"
echo "Mise A Jour terminée en $elapsed_time secondes"
echo "______________________________________________"

