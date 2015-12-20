:: This script installs the dotfiles for Windows. Since Windows lacks
:: access to most decent software, only a few of the dotfiles are
:: relevant on this platform. No fancy loops needed here.

@echo off

set HOME=%HOMEDRIVE%%HOMEPATH%

echo Installing vlcrc
if not exist %APPDATA%\vlc mkdir %APPDATA%\vlc
attrib -r %HOME%\AppData\Roaming\vlc\vlcrc
copy _config\vlc\vlcrc %HOME%\AppData\Roaming\vlc\vlcrc
attrib +r %HOME%\AppData\Roaming\vlc\vlcrc

echo Installing mpv.conf
if not exist %APPDATA%\mpv mkdir %APPDATA%\mpv
copy _config\mpv\mpv.conf %APPDATA%\mpv\mpv.conf
copy _config\mpv\input.conf %APPDATA%\mpv\input.conf

echo Installing _vimperatorrc
copy _vimperatorrc %HOME%

echo Installing bash dotfiles
copy _bashrc       %HOME%\.bashrc
copy _bash_aliases %HOME%\.bash_aliases
copy _bash_profile %HOME%\.bash_profile

echo Installing _gitconfig
copy _gitconfig %HOME%\.gitconfig
