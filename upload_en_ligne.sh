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
$HOME/.local/share/gem/ruby/3.0.0/bin/neocities push --prune website

# Message de fin
echo "Upload finished!"
echo "Press 'q' to quit."
while true; do
    read -n 1 -r key
    if [ "$key" = 'q' ]; then
        break
    fi
done