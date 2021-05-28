:: This script installs the dotfiles for Windows. Since Windows lacks access
:: to most decent software, only a few of the dotfiles are relevant on this
:: platform. No fancy loops needed here.

@echo off

echo Installing mpv.conf
if not exist %APPDATA%\mpv mkdir %APPDATA%\mpv
copy _config\mpv\mpv.conf %APPDATA%\mpv\mpv.conf
copy _config\mpv\input.conf %APPDATA%\mpv\input.conf

echo Installing _gitconfig
copy _gitconfig %USERPROFILE%\.gitconfig

echo Installing _vim
copy _vimrc %USERPROFILE%\_vimrc
