#!/bin/sh
# Hook to easily git push and neocities push
source /home/velo/.bashrc
git add .
read -p "Message pour l'historique( et appui sur entré):" commit_message
git commit -m "$commit_message" 
git push -u origin master
read -p "Upload to neocities? (y/n): " diff_confirm
if [ "$diff_confirm" != "y" ]; then
    echo "Not uploaded to neocities"
    exit 1
fi
neocities push website
echo "Upload finished!"
echo "Press 'q' to quit."
while true; do
    read -n 1 -r key
    if [ "$key" = 'q' ]; then
        break
    fi
done