#!/bin/bash

DELAY=600
DIR=~/.wallpaper
SHOW="feh --bg-fill"

find $DIR -type f -print0 | shuf -z | while read -d $'\0' image
do
    $SHOW "$image"
    if [ "$1" == --once ]; then exit; fi
    sleep $DELAY
done
