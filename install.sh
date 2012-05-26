#!/bin/bash

find -regex "./_.*" -type f -print0 | while read -d $'\0' file
do
    dotfile=${file/_/.}
    echo Installing $dotfile
    if [ ! -e $(dirname ~/$dotfile) ]; then
        mkdir -p $(dirname ~/$dotfile)
    fi
    ln -fs $(pwd)/$file ~/$dotfile
done

ln -sf /dev/null ~/.bash_history
