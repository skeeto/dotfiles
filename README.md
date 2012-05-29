# Personal dotfiles

This repository versions my personal dotfiles. It can be cloned to
anywhere and the dotfiles installed by running `install.sh`.

For convenience, I don't actually want these files hidden in the
repository, so the dots are replaced with underscores.

## Openbox

An Openbox config is included. To use it fully, make sure you install
`feh` (wallpapers) and `xcompmgr` (window transparency). I like to use
`lxterminal`, which works properly with `xcompmgr`.

    apt-get install openbox feh xcompmgr lxterminal

I'm also using Thunar for occasional file/mount management and `xlock`
for screen locking.

    apt-get install thunar xlockmore

Check rc.xml for all of my fancy Openbox keyboard shortcuts.

## Wallpapers

Wallpaper stuff is installed in `~/.wallpaper`. It includes a script
that uses `feh` to change wallpapers randomly every 10
minutes. There's also a script `fetch.sh`, which will download my
wallpaper selection, hosted externally. The Openbox config will start
this tool automatically.
