#!/bin/sh
set -eu

MARKDOWN=smu  # Or use 'pandoc' or your preferred converter
POST_DIR="./blog"
OUTPUT_DIR="../website/blogposts"
BLOG_INDEX="../website/blog.html"

mkdir -p "$OUTPUT_DIR"

# Generate blog.html
{
    echo "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>Blog</title></head><body>"
    echo "<h1>Blog</h1><ul>"

    for f in "$POST_DIR"/*.md; do
        [ -e "$f" ] || continue
        title=$(sed -n 's/^# //p' "$f" | head -n1)
        created=$(git log --format='%aI' -- "$f" | tail -1 || echo "draft")
        date=$(echo "$created" | cut -dT -f1)

        base=$(basename "$f" .md)
        out="$OUTPUT_DIR/$base.html"

        $MARKDOWN "$f" > "$out"

        printf '<li>%s — <a href="blogposts/%s.html">%s</a></li>\n' "$date" "$base" "$title"
    done

    echo "</ul></body></html>"
} > "$BLOG_INDEX"

# Git commit block for blog posts
if git diff --quiet -- blog; then
    echo "No blog changes to commit."
else
    git add blog/*
    git commit -m "New or updated blog posts"
fi
