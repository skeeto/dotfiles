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
`feh` (wallpapers) and `xcompmgr` (window transparency). I like to use
`lxterminal`, which works properly with `xcompmgr`.

    apt-get install openbox feh xcompmgr lxterminal

There's a `.xsession` file for launching Openbox, so the display
manager should be told to use something like "user preference" or
"system default" rather than "Openbox".

Check rc.xml for all of my fancy Openbox keyboard shortcuts. Examples,

 * W-n -- launch a terminal
 * C-A-*arrow* -- move focus to another desktop
 * C-S-*arrow* -- move window, with focus, to another desktop
 * W-*arrow* -- change focus to window in a direction
 * W-S-*arrow* -- move window to an edge in a direction
 * C-W-*arrow* -- grow window to an edge
 * W-l -- toggle the window always-on-top

The desktop environment traditionally fills the role for a number of
common activities. Since I'm using bare-bones Openbox, I have a number
of independent applications for the job.

### Application launching

I use dmenu to launch applications.

    apt-get install dmenu

 * A-F1 -- use dmenu to launch an application

### Mounting

I'm using Thunar and `pmount` (command line) for removable drive
mounting.

    apt-get install thunar pmount

 * W-e -- launch Thunar (file management)

### Screen locking

`i3lock` is used for screen locking.

    apt-get install i3lock

 * C-A-l -- lock the screen

### Network management

An good tool for network management is Wicd.

    apt-get install wicd wicd-gtk wicd-curses

 * W-w -- launch Wicd client

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
