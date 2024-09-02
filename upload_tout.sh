#!/bin/sh
# Hook to easily git push and neocities push
read -p "Message pour l'historique(obligatoire):" commit_message
#______________________________________________________________________________________
#Image processing

# Directories
BASE_DIR="$HOME/bronze.neocities.org/website"
IMAGE_DIR="$BASE_DIR/img/gallerie"
ORIGINAL_DIR="./original"
RESIZED_DIR="$IMAGE_DIR"
OUTPUT_FILE="$HOME/bronze.neocities.org/website/galerie_list.yaml"
NEOCITIES_PATH="$HOME/.local/share/gem/ruby/3.0.0/bin/neocities"
PROCESSED_FILE="$IMAGE_DIR/processed_images.txt"

# Fonction pour redimensionner et compresser les images
resize_and_compress_images() {
    echo "Redimensionnement et compression des images..."
    max_number=$(ls -1 $IMAGE_DIR/*b.webp 2>/dev/null | awk -F '/' '{print $NF}' | awk -F 'b.webp' '{print $1}' | sort -nr | head -n1)
    max_number=${max_number:-0} # Définir à 0 si aucune image trouvée
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

# Fonction pour générer galerie_list.yaml
generate_image_list() {
    echo "Génération de galerie_list.yaml..."
    echo "images:" > $OUTPUT_FILE

    for image in $(ls $IMAGE_DIR/*b.webp | sort -Vr); do
        base_name=$(basename "$image" b.webp)
        echo "  - src: img/gallerie/${base_name}b.webp" >> $OUTPUT_FILE
        echo "    srct: img/gallerie/${base_name}s.webp" >> $OUTPUT_FILE
        echo "    title: \"$base_name\"" >> $OUTPUT_FILE
        echo "    numero: $base_name" >> $OUTPUT_FILE
    done
}

# Début du chronomètre
start_time=$(date +%s)

# Redimensionner et compresser les images
resize_and_compress_images

# Générer galerie_list.yaml
generate_image_list

echo "Suppression des images originales..."
rm -f "$ORIGINAL_DIR"/*

#______________________________________________________________________________________
#Envoi vers github
echo "______________________________________________"
echo "Envoi vers Github"
cd $HOME/bronze.neocities.org
git add .
git commit -m "$commit_message" 
git push -u origin master


# Fin du chronomètre et calcul du temps écoulé
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

# Message final
echo "______________________________________________"
echo "MAJ terminé en $elapsed_time secondes !"
rm $PROCESSED_FILE