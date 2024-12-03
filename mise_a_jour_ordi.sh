#!/bin/bash

# Prévisualiser les fichiers et dossiers qui seraient supprimés
clean_output=$(git clean -fdn)

# Vérifier si git clean -fdn retourne quelque chose
if [ -n "$clean_output" ]; then
    echo "$clean_output"
    # Demander une confirmation
    read -p "Voulez-vous continuer et supprimer ces fichiers ? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Opération annulée."
        exit 0
    fi

    # Supprimer les fichiers et dossiers non suivis
    git clean -fd
fi

# Mettre à jour le dépôt local
git pull

