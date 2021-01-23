#!/bin/sh

set -e
IFS='
'

lnflags=-s
install_scripts=yes
install_private=no
high_dpi=auto

usage() {
    cat << EOF
usage: install.sh [options]

OPTIONS:
  -d    Assume high DPI (larger fonts)
  -h    Show this message
  -l    Install config files as hard links
  -p    Install private dotfiles
EOF
    exit $1
}

## Parse command line switches
while getopts "dhlp" option; do
    case "$option" in
        d) high_dpi=yes ;;
        h) usage 0 ;;
        l) lnflags= ;;
        p) install_private=yes ;;
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
    dest="$HOME/.${dotfile#_}"
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
for source in _*; do  # Globbing expansion is sorted
    for dotfile in $(find "$source" -type f | sort); do
        install "$dotfile"
    done
done

## Special cases
mkdir -p ~/.vim/spell
ln -sf /dev/null ~/.bash_history
chmod 700 ~/.gnupg
chmod -w _config/vlc/vlcrc  # Disables annoying VLC clobbering

if [ ! -e "$HOME/.vimrc_local" -a $high_dpi != auto ]; then
    if [ $high_dpi = yes ]; then
        cat >"$HOME/.vimrc_local" <<EOF
if has("x11")
    let &guifont="Noto Mono 13"
endif
EOF
    else
        rm -f "$HOME/.vimrc_local"
    fi
fi

if [ ! -e "$HOME/.config/kitty/kitty_local.conf" -o $high_dpi != auto ]; then
    if [ $high_dpi = yes ]; then
        echo font_size 12 >"$HOME/.config/kitty/kitty_local.conf"
    else
        echo >"$HOME/.config/kitty/kitty_local.conf"
    fi
fi

if [ ! -e ~/.Xresources.h -o $high_dpi != auto ]; then
    if [ $high_dpi = yes ]; then
        echo "#define FONT_SIZE 12" > ~/.Xresources.h
    else
        echo "#define FONT_SIZE 10" > ~/.Xresources.h
    fi
fi

## Reload .Xresources
if [ -n "$DISPLAY" ]; then
    xrdb -I$HOME -merge ~/.Xresources 2> /dev/null
fi

## Compile ssh config
printf "## WARNING: do not edit directly\n" > ~/.ssh/config
for f in ~/.ssh/config.d/*; do
    printf '\n' >> ~/.ssh/config
    cat "$f" >> ~/.ssh/config
done
