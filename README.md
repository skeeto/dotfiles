# Personal dotfiles

This repository versions my personal dotfiles. It can be cloned to
anywhere and the dotfiles installed by running `install.sh`. I use
Debian-based systems almost exclusively, so these dotfiles reflect
Debian's defaults.

For convenience, I don't actually want these files hidden in the
repository, so the dots are replaced with underscores.

## Private (encrypted) dotfiles

Dotfiles ending in ".enchive" will be [decrypted][enchive] before
installation, with the ".enchive" stripped from the name. Unlike the
other dotfiles, these are not symlinked.

## Openbox

An Openbox config is included. To use it fully, make sure you install
`feh` (wallpapers) and `compton` (window transparency).

    apt-get install openbox feh compton

There's a `.xsession` file for launching Openbox, so the display
manager should be told to use something like "user preference" or
"system default" rather than "Openbox".

Check rc.xml for all of my fancy Openbox keyboard shortcuts. Examples,

 * <kbd>W-n</kbd>: launch a terminal
 * <kbd>C-A-[arrow]</kbd>: move focus to another desktop
 * <kbd>C-S-[arrow]</kbd>: move window, with focus, to another desktop
 * <kbd>W-[left/right]</kbd>: tile left/right (like Windows)
 * <kbd>W-S-[arrow]</kbd>: move window to an edge in a direction
 * <kbd>W-A-[arrow]</kbd>: grow window to nearest edge in a direction
 * <kbd>W-l</kbd>: toggle the window always-on-top

The desktop environment traditionally fills the role for a number of
common activities. Since I'm using bare-bones Openbox, I have a number
of independent applications for the job.

### Application launching

I use dmenu to launch applications.

    apt-get install dmenu

 * <kbd>A-F1</kbd>: use dmenu to launch an application

### Mounting

I'm using `pmount` (command line) for removable drive mounting.

    apt-get install pmount

### Screen locking

`i3lock` is used for screen locking.

    apt-get install i3lock

 * <kbd>C-A-l</kbd>: lock the screen

### Wallpapers

Wallpaper stuff is installed in `~/.wallpaper/`. It includes a script
that uses `feh` to change wallpapers randomly every 10 minutes. The
Openbox config will start this tool automatically on login. There's
also a script `fetch.sh`, which will download my wallpaper selection,
hosted externally.

Any images thrown in `~/.wallpaper/` will become part of the random
background rotation.

## Other applications

Other configured applications include Git, Vimperator (Firefox), gdb,
mutt, procmail, xterm, urxvt, bash, nethack, mpv, vlc, quilt, and
s3cmd.

My Emacs config is much too complicated to be included here. It's in
[a separate repository](https://github.com/skeeto/.emacs.d).


[enchive]: https://github.com/skeeto/enchive
