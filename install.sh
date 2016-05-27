#!/usr/bin/env bash

set -e

AWK=awk
MKDIR=mkdir
if find --version &> /dev/null; then
    # Looks like GNU coreutils/findutils
    CHMOD=chmod
    FIND=find
    LN=ln
else
    # Guess GNU tools have "g" prefix
    CHMOD=gchmod
    FIND=gfind
    LN=gln
fi

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
$CHMOD go-rwx gnupg
$LN -Tsf $(pwd)/gnupg ~/.gnupg

## Install scripts
ROOT=~/.local/bin
$MKDIR -p $ROOT
if [ -z "$NO_SCRIPTS" ]; then
    echo Installing $ROOT
    $FIND bin/ -type f | xargs -I{} ln -fs $(pwd)/{} "$ROOT"
fi

## Install each _-prefixed file
$FIND . -regex "./_.*" -type f -print0 | sort -z | while read -d $'\0' file
do
    dotfile=${file/.\/_/.}
    decfile=${dotfile/.priv.gpg/}

    ## Install directory first
    if [ ! -e $(dirname ~/$dotfile) ]; then
        $MKDIR -p -m 700  $(dirname ~/$dotfile)
    fi

    ## Install the file
    if [[ "$file" =~ priv.gpg$ ]]; then
        ## Decrypt into place
        if [ -z "$NO_PRIVATE" -a $file -nt ~/$decfile ]; then
            echo Decrypting ~/$decfile
            gpg --quiet --yes --decrypt --output ~/$decfile $file
            $CHMOD go-rwx ~/$decfile
        else
            echo Skipping $dotfile
        fi
    else
        ## Create a link to the repository version
        echo Installing $dotfile
        $LN -fs $(pwd)/$file ~/$dotfile
        $CHMOD go-rwx $file
    fi
done

## Special cases
$LN -sf /dev/null ~/.bash_history
$CHMOD -w _config/vlc/vlcrc  # Disables annoying VLC clobbering
$AWK 'FNR==1{print ""}1' ~/.ssh/config.d/* > ~/.ssh/config
