#!/bin/bash

usage() {
cat << EOF
usage: $0 [options]

OPTIONS:
  -h    Show this message
  -p    Don't install private dotfiles
  -s    Don't install bin/ scripts
EOF
}

## Parse command line switches
while getopts "hps" OPTION
do
    case $OPTION in
        h)
            usage
            exit
            ;;
        p)
            NO_PRIVATE=1
            ;;
        s)
            NO_SCRIPTS=1
            ;;
        ?)
            usage
            exit 1
             ;;
    esac
done

## Setup GPG
echo Installing .gnupg
chmod go-rwx gnupg
ln -Tsf $(pwd)/gnupg ~/.gnupg

## Install scripts
ROOT=~/.local/bin
mkdir -p $ROOT
if [ -z "$NO_SCRIPTS" ]; then
    echo Installing $ROOT
    find bin/ -type f | xargs -I{} ln -fs $(pwd)/{} "$ROOT"
fi

## Install each _-prefixed file
find . -regex "./_.*" -type f -print0 | sort -z | while read -d $'\0' file
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
        if [ -z "$NO_PRIVATE" -a $file -nt ~/$decfile ]; then
            echo Decrypting ~/$decfile
            gpg --quiet --yes --decrypt --output ~/$decfile $file
            chmod go-rwx ~/$decfile
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

## Special cases
ln -sf /dev/null ~/.bash_history
chmod -w _config/vlc/vlcrc  # Disables annoying VLC clobbering
awk 'FNR==1{print ""}1' ~/.ssh/config.d/* > ~/.ssh/config
