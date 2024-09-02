#!/bin/sh
# Hook to easily git push and neocities push

#Envoi vers github
cd $HOME/bronze.neocities.org
git add .
read -p "Message pour l'historique( et appui sur entré):" commit_message
git commit -m "$commit_message" 
git push -u origin master


if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
else
    source "$HOME/.zprofile"
fi

#Push vers neo
start_time=$(date +%s)
$HOME/.local/share/gem/ruby/3.0.0/bin/neocities push --prune website
# Fin du chronomètre et calcul du temps écoulé
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

# Message final
echo "MAJ terminé en $elapsed_time secondes !"
done