#!/bin/sh

set -e

delay=600
wallpapers="$HOME/.wallpaper"

IFS='
'
while true; do
    ## "sort -R" is slightly more portable than "shuf"
    images="$(find "$wallpapers" -type f | sort -R)"
    for image in $images; do
        feh --bg-fill "$image"
        if [ "$1" = --once ]; then
            exit 0;
        fi
        sleep $delay
    done
done
