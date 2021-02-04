#!/usr/bin/env bash
source ./bin/copy_dotfile

# Install softwareupdate
# check current OS
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

if [ ${unameOut} == "Mac" ]; then
    # Do something under Mac OS X platform
elif [ ${unameOut} == "Linux" ]; then
    # Do something under GNU/Linux platform
elif [ ${unameOut} == "MinGw" ]; then
    # Do something under 32 bits Windows NT platform
fi
# Symbolic links to config
ln -sf ~/.dotfiles/vimrc ~/.vimrc
ln -sf ~/.dotfiles/zsh/zshrc ~/.zshrc
ln -sf ~/.dotfiles/tmux.conf ~/.tmux.conf
ln -sf ~/.dotfiles/doom.d ~/.doom.d
