#!/bin/sh
## Fetches my personal collection of nature wallpapers.

set -e -- \
    kde.tar \
    misc.tar \
    100-wallpapers.tar \
    large-set.tar \
    Kelsey-Wellons-Wallpaper-Collection-1.tar
base=http://skeeto.s3.amazonaws.com/wallpapers
for tar; do
    curl "$base/$tar" | tar -xvf -
done
