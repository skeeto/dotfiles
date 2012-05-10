#!/bin/bash

for file in _*
do
    dotfile=${file/_/.}
    echo Installing $dotfile
    ln -fs $(pwd)/$file ~/$dotfile
done

ln -sf /dev/null ~/.bash_history
