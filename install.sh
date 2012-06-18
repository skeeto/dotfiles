#!/bin/bash

## Setup GPG
echo Installing .gnupg
chmod go-rwx gnupg
ln -sf $(pwd)/gnupg ~/.gnupg

## Install each _-prefixed file
find -regex "./_.*" -type f -print0 | sort -z | while read -d $'\0' file
do
    dotfile=${file/.\/_/.}
    decfile=${dotfile/.priv.gpg/}

    ## Install directory first
    if [ ! -e $(dirname ~/$dotfile) ]; then
        mkdir -p -m 700  $(dirname ~/$dotfile)
    fi

    ## Install the file
    if [[ "$file" =~ priv.gpg$ ]]; then
        ## Decrypt into place
        if [ $file -nt ~/$decfile ]; then
            echo Decrypting ~/$decfile
            gpg --quiet --yes --decrypt --output ~/$decfile $file
        else
            echo Skipping $dotfile
        fi
    else
        ## Create a link to the repository version
        echo Installing $dotfile
        ln -fs $(pwd)/$file ~/$dotfile
        chmod go-rwx $file
    fi
done

ln -sf /dev/null ~/.bash_history
