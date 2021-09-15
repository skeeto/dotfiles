PS1='\[\e[92m\]w64\[\e[38;2;255;0;255m\]\w\[\e[0m\e[2 q\] '

export EXE=".exe"

export PYTHONHOME="$HOME/python"
PATH="$PATH;$PYTHONHOME"

export JAVA_HOME="$HOME/jdk"
PATH="$PATH;$JAVA_HOME/bin"

alias g="git"
alias s="less -SR"
alias b="make -kj$NUMBER_OF_PROCESSORS"
alias cl="cl /nologo"
alias nmake="nmake /nologo"

hh() {
    hastyhex -p "$@" | less -FR
}

mini() {
    mode 80,24
}
