#!/usr/bin/env bash

start_time=$(date +%s)

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
    echo "=============================================="
    echo "Traitement des nouvelles images"
    echo "=============================================="

    echo "→ Recherche du prochain numéro disponible..."

    # Extraire tous les numéros déjà utilisés dans le YAML
    used_numbers=$(grep -oP '^    numero: \K[0-9]+' "$OUTPUT_FILE")

    # Trouver le maximum
    max_number=0
    for n in $used_numbers; do
        if (( n > max_number )); then
            max_number=$n
        fi
    done

    # Prochain numéro = max + 1
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

    echo " Traitement des image términé"
}

################################################################################
# 2. Génération du YAML (avec ordre manuel)
################################################################################

generate_image_list() {
    echo ""
    echo "=============================================="
    echo "Génération de galerie_list.yaml..."
    echo "=============================================="
    # Vérifier qu'on est en bash (safety)
    if [ -z "$BASH_VERSION" ]; then
        echo "Erreur : ce script doit être exécuté avec bash."
        return 1
    fi

    declare -A existing_order
    max_existing_order=0

    # Parse existing YAML to get orders (accept "- src:" with optional spaces)
    if [ -f "$OUTPUT_FILE" ]; then
        current_src=""
        while IFS= read -r line || [ -n "$line" ]; do
            if [[ $line =~ ^[[:space:]]*-[[:space:]]*src:[[:space:]]*img/gallerie/([^[:space:]]+) ]]; then
                current_src="${BASH_REMATCH[1]}"
            elif [[ $line =~ ^[[:space:]]*order:[[:space:]]*([0-9]+) ]]; then
                order_value="${BASH_REMATCH[1]}"
                if [[ -n "$current_src" ]]; then
                    existing_order["$current_src"]="$order_value"
                fi
                if (( order_value > max_existing_order )); then
                    max_existing_order=$order_value
                fi
            fi
        done < "$OUTPUT_FILE"
        echo "→ Ordre maximum existant : $max_existing_order"
    else
        echo "→ Aucun YAML existant trouvé."
    fi

    # Create a temporary directory for per-image blocks
    tmpdir=$(mktemp -d) || { echo "Erreur: impossible de créer tmpdir"; return 1; }

    # Ensure we handle the case of no images gracefully
    shopt -s nullglob
    images=( "$IMAGE_DIR"/*b*.webp )
    if [ ${#images[@]} -eq 0 ]; then
        echo "→ Aucun fichier image trouvé dans $IMAGE_DIR"
        # Create empty YAML
        { echo "images:"; printf "\n"; } > "$OUTPUT_FILE"
        rmdir "$tmpdir"
        return 0
    fi

    # Iterate in natural (version) order so numbering is consistent
    IFS=$'\n'
    for image in $(ls "$IMAGE_DIR"/*b*.webp 2>/dev/null | sort -V); do
        base_name=$(basename "$image" .webp)

        if [[ "$base_name" == *"_vendu"* ]]; then
            status="vendu"
        else
            status="en_vente"
        fi

        clean_base_name="${base_name%_vendu}"
        image_number="${clean_base_name%%b*}"

        price="x"; dimensions="x"; weight="x"
        if [[ "$clean_base_name" == *"_"* ]]; then
            IFS='_' read -r -a parts <<< "$clean_base_name"
            price="${parts[1]}"
            dimensions="${parts[2]}"
            weight="${parts[3]}"
        fi

        description=""
        [[ "$price" != "x" ]] && description+="${price}€"
        [[ "$dimensions" != "x" ]] && description+="${description:+, }${dimensions}cm"
        [[ "$weight" != "x" ]] && description+="${description:+, }${weight}kg"

        key="${base_name}.webp"
        if [[ -n "${existing_order["$key"]}" ]]; then
            order_value="${existing_order["$key"]}"
        else
            order_value=$((max_existing_order + 1))
            max_existing_order=$order_value
            echo "  → Nouvelle image détectée : $base_name (order=$order_value)"
        fi

        # Create a filename padded by order to allow lexical sort (pad to width 6)
        printf -v orderpad "%06d" "$order_value"
        blockfile="$tmpdir/${orderpad}_${base_name}.block"

        {
            echo "  - src: img/gallerie/${base_name}.webp"
            echo "    srct: img/gallerie/${image_number}s.webp"
            echo "    title: \"${image_number}:#${status}\""
            echo "    numero: ${image_number}"
            echo "    order: ${order_value}"
            echo "    description: \"${description}\""
            # ensure file ends with a blank line (separator)
            printf "\n"
        } > "$blockfile"
    done
    unset IFS
    shopt -u nullglob

    # Now concatenate files in descending order (newest first)
    {
        echo "images:"
        printf "\n"
        # list files sorted reverse (highest order first)
        ls -1 "$tmpdir" | sort -r | while IFS= read -r f; do
            cat "$tmpdir/$f"
        done
    } > "$OUTPUT_FILE"

    # Cleanup
    rm -rf "$tmpdir"

    echo "galerie_list.yaml mis à jour."
}


#################################################################################
## 3. Normalisation des ordres dans le YAML
#################################################################################

#!/bin/bash

normalize_yaml_order() {
    local yaml_file="$1"
    [[ -z "$yaml_file" ]] && { echo "Usage: normalize_yaml_order <fichier.yaml>" >&2; return 1; }
    [[ ! -f "$yaml_file" ]] && { echo "Fichier introuvable: $yaml_file" >&2; return 1; }

    echo "→ Normalisation des ordres dans $yaml_file"

    # ------------------------------------------------------------
    # 1. Lecture du YAML → découpage en blocs individuels
    # ------------------------------------------------------------
    local blocks=()
    local current_block=""
    local in_block=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+src: ]]; then
            [[ $in_block -eq 1 ]] && blocks+=("$current_block")
            current_block="$line"
            in_block=1
        else
            [[ $in_block -eq 1 ]] && current_block+=$'\n'"$line"
        fi
    done < "$yaml_file"
    [[ -n "$current_block" ]] && blocks+=("$current_block")

    # ------------------------------------------------------------
    # 2. Extraction des champs pour chaque élément
    # ------------------------------------------------------------
    declare -A src order numero title description srct
    local keys=()

    for block in "${blocks[@]}"; do
        # Extraire src
        local src_val=""
        if [[ "$block" =~ src:[[:space:]]+img/gallerie/([^[:space:]]+) ]]; then
            src_val="${BASH_REMATCH[1]}"
        else
            echo "⚠️  Bloc sans src valide, ignoré" >&2
            continue
        fi

        # Extraire order
        local order_val=""
        if [[ "$block" =~ order:[[:space:]]*([0-9]+) ]]; then
            order_val="${BASH_REMATCH[1]}"
        else
            echo "⚠️  Bloc sans order pour $src_val, ignoré" >&2
            continue
        fi

        # Extraire numero
        local numero_val=""
        if [[ "$block" =~ numero:[[:space:]]*([0-9]+) ]]; then
            numero_val="${BASH_REMATCH[1]}"
        else
            echo "⚠️  Bloc sans numero pour $src_val, ignoré" >&2
            continue
        fi

        # Extraire title et description
        local title_val=""
        [[ "$block" =~ title:[[:space:]]*\"([^\"]*)\" ]] && title_val="${BASH_REMATCH[1]}"

        local desc_val=""
        [[ "$block" =~ description:[[:space:]]*\"([^\"]*)\" ]] && desc_val="${BASH_REMATCH[1]}"

        # Extraire srct (ou le construire)
        local srct_val="img/gallerie/${src_val%.webp}s.webp"
        [[ "$block" =~ srct:[[:space:]]+(img/gallerie/[^[:space:]]+) ]] && srct_val="${BASH_REMATCH[1]}"

        # Stockage
        src["$src_val"]="$src_val"
        order["$src_val"]="$order_val"
        numero["$src_val"]="$numero_val"
        title["$src_val"]="$title_val"
        description["$src_val"]="$desc_val"
        srct["$src_val"]="$srct_val"
        keys+=("$src_val")
    done

    local nb=${#keys[@]}
    [[ $nb -eq 0 ]] && { echo "Aucun élément trouvé." >&2; return 1; }

    # ------------------------------------------------------------
    # 3. Trier les clés par order décroissant, puis numero décroissant
    # ------------------------------------------------------------
    local sorted_keys=()
    while IFS= read -r key; do
        sorted_keys+=("$key")
    done < <(
        for k in "${keys[@]}"; do
            printf "%010d|%010d|%s\n" "${order[$k]}" "${numero[$k]}" "$k"
        done | sort -nr -t'|' -k1,1 -k2,2 | cut -d'|' -f3
    )

    # ------------------------------------------------------------
    # 4. Attribution de nouveaux ordres uniques (décroissants stricts)
    # ------------------------------------------------------------
    declare -A new_order
    local last_order=9999999  # plus grand que tout order existant

    for k in "${sorted_keys[@]}"; do
        local current="${order[$k]}"
        # On veut que le nouvel ordre soit ≤ current et < last_order
        # On prend le minimum entre current et (last_order - 1)
        local candidate=$(( current < last_order ? current : last_order - 1 ))
        # Si candidate < 0, on le met à 0 (mais normalement pas nécessaire)
        [[ $candidate -lt 0 ]] && candidate=0
        new_order["$k"]="$candidate"
        last_order="$candidate"
    done

    # ------------------------------------------------------------
    # 5. Reconstruire le YAML trié par nouvel ordre décroissant
    # ------------------------------------------------------------
    local tmpfile=$(mktemp)
    {
        echo "images:"
        echo ""
        # On retrie les clés par new_order décroissant
        for k in $(for k in "${sorted_keys[@]}"; do echo "${new_order[$k]}|$k"; done | sort -nr -t'|' -k1,1 | cut -d'|' -f2); do
            echo "  - src: img/gallerie/${k}"
            echo "    srct: ${srct[$k]}"
            [[ -n "${title[$k]}" ]] && echo "    title: \"${title[$k]}\""
            echo "    numero: ${numero[$k]}"
            echo "    order: ${new_order[$k]}"
            echo "    description: \"${description[$k]}\""
            echo ""
        done
    } > "$tmpfile"

    mv "$tmpfile" "$yaml_file"
    echo "✅ YAML normalisé : ${#sorted_keys[@]} éléments, ordres uniques et triés décroissants."
}


################################################################################
# 3. Nettoyage
################################################################################
echo ""
echo "=============================================="
echo "Nettoyage"
echo "=============================================="


resize_and_compress_images
generate_image_list
normalize_yaml_order "$OUTPUT_FILE"

echo "→ Suppression des originaux..."
find "$ORIGINAL_DIR" -type f ! -name ".gitkeep" -exec rm -f {} +


echo "Nettoyage effectué"


################################################################################
# 4. Git Push
################################################################################
echo ""
echo "=============================================="
echo "Envoi vers GitHub"
echo "=============================================="

cd "$workpath"
git add .
git commit -m "$commit_message"
git push -u origin master

echo "Envoi terminé"


################################################################################
# 5. Suivi GitHub Actions
################################################################################
echo ""
echo "=============================================="
echo "Suivi des Actions GitHub"
echo "=============================================="

dots=0
max_dots=3
timeout=30

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



################################################################################
# FINAL MESSAGE
################################################################################
end_time=$(date +%s)
duration=$(( end_time - start_time ))

# Conversion en minutes et secondes
minutes=$(( duration / 60 ))
seconds=$(( duration % 60 ))

echo ""
echo "========================================================================"
echo "La Mise à jour a été effectuée en  "${minutes}m${seconds}s" avec succès!"
echo "========================================================================"
