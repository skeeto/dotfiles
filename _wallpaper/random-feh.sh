#!/bin/bash

DELAY=600
DIR=~/.wallpaper

find $DIR -type f -print0 | shuf -z | while read -d $'\0' image
do
    feh --bg-fill "$image"
    if [ "$1" == --once ]; then exit; fi
    sleep $DELAY
done
