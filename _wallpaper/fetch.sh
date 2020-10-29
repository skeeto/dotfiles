#!/bin/sh
## Fetches my personal collection of nature wallpapers.

set -e -- \
    Kelsey-Wellons-Wallpaper-Collection-1.tar \
    Kelsey-Wellons-Wallpaper-Collection-2.tar \
    Kelsey-Wellons-Wallpaper-Collection-3.tar \
    Kelsey-Wellons-Wallpaper-Collection-4.tar
base=http://skeeto.s3.amazonaws.com/wallpapers
for tar; do
    curl "$base/$tar" | tar -xvf -
done
