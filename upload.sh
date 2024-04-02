#!/bin/sh
# Hook to easily git push and neocities push

git add .
read -p "Enter commit:" commit_message
git commit -m "$commit_message" 
git push -u origin master
read -p "Upload to neocities? (y/n): " diff_confirm
if [ "$diff_confirm" != "y" ]; then
    echo "Not uploaded to neocities"
    exit 1
fi
neocities push website