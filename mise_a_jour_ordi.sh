#!/bin/bash

git pull



echo "Press 'q' to quit."
while true; do
    read -n 1 -r key
    if [ "$key" = 'q' ]; then
        break
    fi
done