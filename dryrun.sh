#!/bin/sh
# Hook to easily git push and neocities push

NEOCITIES_DIR="website"

echo "Adding changes to the staging area..."
git add .

read -p "Enter commit message: " commit_message
echo "Committing changes with message: \"$commit_message\""
git commit -m "$commit_message" 

echo "Pushing changes to the remote repository..."
git push -u origin master

get_changed_files() {
    echo "Getting list of changed files in the commit..."
    git diff --name-only HEAD^ HEAD | grep -v -E '^\s'
}

upload_changed_files() {
    changed_files=$(get_changed_files)
    if [ -z "$changed_files" ]; then
        echo "No files changed in the commit. Exiting."
        exit 0
    fi
    
    echo "Dry run: Printing upload commands instead of executing..."
    while IFS= read -r file; do
        directory=$(dirname "$file")
        filename=$(basename "$file")
        echo "Would upload \"$filename\" to directory \"$directory\""
    done <<< "$changed_files"
}

upload_changed_files
