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
