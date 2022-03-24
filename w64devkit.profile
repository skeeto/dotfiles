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

export GIT_TERMINAL_PROMPT=0
PATH="$PATH;$HOME/git/cmd"

alias b="make -kj$NUMBER_OF_PROCESSORS"
alias cl="cl /nologo"
alias g="git"
alias m="mpv --really-quiet"
alias nmake="nmake /nologo"
alias s="less -SR"

doc() {
    case "$1" in
    c*) cmd /c start "" "$HOME/cppreference/en/index.html" ;;
    p*) cmd /c start "" "$HOME/python/Doc/index.html"      ;;
    j*) cmd /c start "" "$HOME/jdk/docs/index.html"        ;;
    w*) cmd /c start "" "$HOME/win32.chm"                  ;;
     *) echo doc: what is $1?; return 1                    ;;
    esac
}

hh() {
    hastyhex -p "$@" | less -FR
}

mini() {
    mode 80,24
}
