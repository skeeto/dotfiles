#!/bin/sh
## Fetches my personal collection of landscape wallpapers.

set -e -- kde.tar misc.tar 100-wallpapers.tar large-set.tar
base=http://skeeto.s3.amazonaws.com/wallpapers
for tar; do
    curl "$base/$tar" | tar -xvf -
done
