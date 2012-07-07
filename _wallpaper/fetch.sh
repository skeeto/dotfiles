#!/bin/bash

## Fetches my personal collection of landscape wallpapers.

base=http://skeeto.s3.amazonaws.com/wallpapers
while read line; do
    wget -O - $base/$line | tar -xv
done <<EOF
kde.tar
misc.tar
100-wallpapers.tar
large-set.tar
EOF
