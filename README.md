# Personal dotfiles

This repository versions my personal dotfiles. It can be cloned to
anywhere and the dotfiles installed by running `install.sh`. I use
Debian-based systems almost exclusively, so these dotfiles reflect
Debian's defaults.

For convenience, I don't actually want these files hidden in the
repository, so the dots are replaced with underscores.

## Private (encrypted) dotfiles

Dotfiles ending in ".priv.gpg" will be decrypted before installation,
with the ".priv.gpg" stripped from the name. You probably want
`gpg-agent` running if you want to avoid entering your passphrase
multiple times. Unlike the other dotfiles, these are not symlinked
since there is nothing to symlink to.

I'm using `keychain` to start `ssh-agent` and `gpg-agent` so make sure
it's installed along with the agents.

    apt-get install keychain

You may have noticed, yes, I have my private PGP key in here!
Dangerous?! Maybe, it's an experiment. It's got a strong passphrase on
it and I've pumped up the key strengthening settings in GPG, like so,

    gpg --s2k-cipher-algo AES256 --s2k-digest-algo SHA512 --s2k-mode 3 \
        --s2k-count 10000000 --edit-key <key id>

Then run `passwd` in the key editor. That's over 10 million rounds of
SHA-512 which takes a half-second to compute on my
laptop. Brute-forcing my passphrase *should* be completely
impractical. I invite anyone to prove me wrong -- since I'd rather be
wrong sooner than later.

## Openbox

An Openbox config is included. To use it fully, make sure you install
`feh` (wallpapers) and `compton` (window transparency). I like to use
`lxterminal`, which works properly with `compton`.

    apt-get install openbox feh compton lxterminal

There's a `.xsession` file for launching Openbox, so the display
manager should be told to use something like "user preference" or
"system default" rather than "Openbox".

Check rc.xml for all of my fancy Openbox keyboard shortcuts. Examples,

 * <kbd>W-n</kbd>: launch a terminal
 * <kbd>C-A-[arrow]</kbd>: move focus to another desktop
 * <kbd>C-S-[arrow]</kbd>: move window, with focus, to another desktop
 * <kbd>W-[arrow]</kbd>: change focus to window in a direction
 * <kbd>W-S-[arrow]</kbd>: move window to an edge in a direction
 * <kbd>W-A-[arrow]</kbd>: grow window to nearest edge in a direction
 * <kbd>W-C-[arrow]</kbd>: shrink window away from an edge in a direction
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

### Network management

A mediocre, but fully standalone, tool for network management is Wicd.

    apt-get install wicd wicd-gtk wicd-curses

 * <kbd>W-w</kbd>: launch Wicd client

### Wallpapers

Wallpaper stuff is installed in `~/.wallpaper/`. It includes a script
that uses `feh` to change wallpapers randomly every 10 minutes. The
Openbox config will start this tool automatically on login. There's
also a script `fetch.sh`, which will download my wallpaper selection,
hosted externally.

Any images thrown in `~/.wallpaper/` will become part of the random
background rotation.

## Other applications

Other configured applications include Git, `indent`, Pentadactyl
(Firefox), quilt (for Debian patches), and s3cmd.

My Emacs config is much too complicated to be included here. It's in
[a separate repository](https://github.com/skeeto/.emacs.d).
