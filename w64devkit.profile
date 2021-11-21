PS1='\[\e[92m\]w64\[\e[38;2;255;0;255m\]\w\[\e[0m\e[2 q\] '

export EXE=".exe"
PATH="$PATH;$HOME/bin"

PATH="$PATH;$HOME/gnupg/bin"

export PYTHONHOME="$HOME/python"
PATH="$PATH;$PYTHONHOME"

export JAVA_HOME="$HOME/jdk"
PATH="$PATH;$JAVA_HOME/bin"

export GOBIN="$HOME/bin"
export GOPATH="$TEMP/go"
PATH="$PATH;$HOME/go/bin"

PATH="$PATH;$HOME/git/cmd"

alias b="make -kj$NUMBER_OF_PROCESSORS"
alias cl="cl /nologo"
alias g="git"
alias m="mpv --really-quiet"
alias nmake="nmake /nologo"
alias s="less -SR"

hh() {
    hastyhex -p "$@" | less -FR
}

mini() {
    mode 80,24
}

genalias() {
    exe="$1"
    base="$(basename "$exe")"
    shift
    if [[ $# -eq 0 ]]; then
        set "$base"
    fi
    cc -DEXE="$exe" -DCMD="$*" -s -Os -nostdlib -ffreestanding \
        -o "$HOME/bin/$base" "$HOME/w64devkit/src/alias.c" -lkernel32
}
