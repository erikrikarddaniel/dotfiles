# ~/.bash_profile: executed by bash(1) for login shells.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# Set environment variables in .pam_environment instead

umask 022

# include .bashrc if it exists
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# set PATH so it includes user's private bin if it exists
if [ -d ~/bin ] ; then
    PATH=~/bin:"${PATH}"
fi

[ -d "${PIXI_HOME:-$HOME/.pixi}/bin" ] && PATH="${PIXI_HOME:-$HOME/.pixi}/bin:$PATH"

# Komplettering
[ -f /etc/profile.d/bash-completion ] && . /etc/profile.d/bash-completion

export VISUAL=vim
export EDITOR="$VISUAL"

export SCREENRC=./.screenrc

