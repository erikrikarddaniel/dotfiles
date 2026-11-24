# dotfiles

Personal config synced across machines. Files here are symlinked into place
from their real locations (e.g. `~/.claude/settings.json` -> `.claude/settings.json`).

## Setup on a new machine

```
git clone git@github.com:erikrikarddaniel/dotfiles.git ~/dotfiles
cp ~/dotfiles/.claude/settings.example.json ~/dotfiles/.claude/settings.json
ln -s ~/dotfiles/.claude/settings.json ~/.claude/settings.json
ln -s ~/dotfiles/.claude/CLAUDE.md ~/.claude/CLAUDE.md
```

## Shell startup files

`.bashrc`, `.bash_aliases`, `.bash_profile` and `.profile` hold only settings shared by all machines.
They are not symlinked.
Each machine has its own real `~/.bashrc` etc. that sources the shared file and adds what is local: conda init, juliaup, linuxbrew, `NXF_*` paths, locale, host aliases.
Installers such as `conda init` then write into the local file, not into this repo.

On a new machine:

```
for f in .bash_aliases .bash_profile .profile; do echo ". ~/dotfiles/$f" > ~/$f; done
printf '. ~/dotfiles/.bashrc\n\n[[ $- == *i* ]] || return\n' > ~/.bashrc
```

Put environment variables in `~/.bash_profile` before its `.` line, so that `.bashrc` already sees them.
Machine-specific interactive setup goes in `~/.bashrc` after the `return` line.

## `.claude/settings.json` is not tracked

Claude Code rewrites that file in full whenever any setting changes -- picking a
model, toggling a plugin -- which reordered keys and left the repo dirty after
every session.
The live file is therefore ignored, and `.claude/settings.example.json` is the
versioned copy.

Copy the template over the live file on a new machine, as above.
After deliberately changing a setting you want to keep, copy it back:

```
cp ~/dotfiles/.claude/settings.json ~/dotfiles/.claude/settings.example.json
```

Nothing syncs the two automatically, so a setting only reaches another machine
once it has been copied back and committed.
