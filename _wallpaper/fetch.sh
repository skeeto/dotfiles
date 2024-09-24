#!/bin/sh
## Fetches my personal collection of nature wallpapers.

set -e -- \
    Kelsey-Wellons-Wallpaper-Collection-1.tar  \
    Kelsey-Wellons-Wallpaper-Collection-2.tar  \
    Kelsey-Wellons-Wallpaper-Collection-3.tar  \
    Kelsey-Wellons-Wallpaper-Collection-4.tar  \
    Kelsey-Wellons-Wallpaper-Collection-5.tar  \
    Kelsey-Wellons-Wallpaper-Collection-6.tar  \
    Kelsey-Wellons-Wallpaper-Collection-7.tar  \
    Kelsey-Wellons-Wallpaper-Collection-8.tar  \
    Kelsey-Wellons-Wallpaper-Collection-9.tar  \
    Kelsey-Wellons-Wallpaper-Collection-10.tar \
    Kelsey-Wellons-Wallpaper-Collection-11.tar \
    Kelsey-Wellons-Wallpaper-Collection-12.tar \
    Kelsey-Wellons-Wallpaper-Collection-13.tar \

base=http://skeeto.s3.amazonaws.com/wallpapers
for tar; do
    curl -s "$base/$tar" | tar -xvf -
done
