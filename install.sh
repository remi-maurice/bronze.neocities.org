#!/bin/bash
sudo pacman -S git
sudo pacman -S github-cli
sudo pacman -S imagemagick
sudo pacman -S code
sudo pacman -S ruby
gem install neocities

gh auth login 

read -p "Please enter your Neocities Api Key:" api_key
NEOCITIES_API_KEY="$api_key"

if ! grep -q "NEOCITIES_API_KEY" ~/.bash_profile && ! grep -q "NEOCITIES_API_KEY" ~/.zprofile; then
    PROFILE_FILE=""
    if [[ -f "$HOME/.bash_profile" ]]; then
        PROFILE_FILE="$HOME/.bash_profile"
    elif [[ -f "$HOME/.zprofile" ]]; then
        PROFILE_FILE="$HOME/.zprofile"
    else
        echo "Error: Neither .bash_profile nor .zprofile found in the home directory." >&2
        exit 1
    fi

    echo 'export PATH="$HOME/.local/share/gem/ruby/3.0.0/bin/:$PATH"' >> "$PROFILE_FILE"
    echo "export NEOCITIES_API_KEY=\"$NEOCITIES_API_KEY\"" >> "$PROFILE_FILE"

    source "$PROFILE_FILE"

    echo "Neocities API key has been added to $PROFILE_FILE."
else
    echo "Neocities API key is already set in your profile file."
fi
