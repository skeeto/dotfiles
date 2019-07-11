#!/bin/sh

set -e
IFS='
'

lnflags=-s
install_scripts=yes
install_private=no

usage() {
    cat << EOF
usage: install.sh [options]

OPTIONS:
  -l    Install config files as hard links
  -p    Install private dotfiles
  -h    Show this message
EOF
    exit $1
}

## Parse command line switches
while getopts "lph" option; do
    case "$option" in
        l) lnflags= ;;
        p) install_private=yes ;;
        h) usage 0 ;;
        ?) usage 1 ;;
    esac
done

## Install scripts
bin=~/.local/bin
mkdir -p "$bin"
if [ $install_scripts = yes ]; then
    echo Installing scripts
    for script in $(find bin -type f -perm -+x); do
        ln -fs -- "$(pwd)/$script" "$bin"
    done
fi

## Installs an individual dotfile
install() {
    dotfile="$1"
    dest="$HOME/.${dotfile#./_*}"
    if [ "$dotfile" = "${dotfile##*.enchive}" ]; then
        echo Installing "$dotfile"
        mkdir -p -m 700 "$(dirname "$dest")"
        chmod go-rwx "$dotfile"
        ln -f $lnflags "$(pwd)/$dotfile" "$dest"
    elif [ $install_private = yes ]; then
        dest="${dest%.enchive}"
        if [ ! -e "$dest" -o "$dotfile" -nt "$dest" ]; then
            echo Decrypting "$dotfile"
            mkdir -p -m 700 "$(dirname "$dest")"
            (umask 0177;
             enchive --agent extract "$dotfile" "$dest")
        else
            echo Skipping "$dotfile"
        fi
    fi
}

## Install each _-prefixed file
for source in $(find . -name '_*' | sort); do
    if [ -d "$source" ]; then
        for dotfile in $(find "$source" -type f | sort); do
            install "$dotfile"
        done
    else
        install "$source"
    fi
done

## Special cases
mkdir -p ~/.vim/spell
ln -sf /dev/null ~/.bash_history
chmod 700 ~/.gnupg
chmod -w _config/vlc/vlcrc  # Disables annoying VLC clobbering

get_dpi() {
    r=$( (xrandr | \
             grep '\<connected\>' | \
             head -n 1 | \
             sed 's/[^0-9]/ /g' | \
             awk '{printf "%.0f\n", $2 / ($6 * 0.0394)}') \
           2>/dev/null)
    if [ -z "$r" ]; then
        echo 96  # fake it
    else
        echo "$r"
    fi
}

## Reload .Xresources
if [ -n "$DISPLAY" ]; then
    dpi="$(get_dpi)"
    if [ "$dpi" -gt 110 ]; then
        font_size=12
    else
        font_size=10
    fi
    echo "#define FONT_SIZE $font_size" > ~/.Xresources.h
    if [ ! -e ~/.dpi ]; then
        echo "export DPI=$(get_dpi)" > ~/.dpi
    fi
    xrdb -I$HOME -merge ~/.Xresources 2> /dev/null
elif [ ! -e ~/.Xresources.h ]; then
    echo "#define FONT_SIZE 10" > ~/.Xresources.h
fi

## Compile ssh config
printf "## WARNING: do not edit directly\n" > ~/.ssh/config
for f in ~/.ssh/config.d/*; do
    printf '\n' >> ~/.ssh/config
    cat "$f" >> ~/.ssh/config
done
