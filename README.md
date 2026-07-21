# dotfiles

Personal config synced across machines. Files here are symlinked into place
from their real locations (e.g. `~/.claude/settings.json` -> `.claude/settings.json`).

## Setup on a new machine

```
git clone git@github.com:erikrikarddaniel/dotfiles.git ~/dotfiles
ln -s ~/dotfiles/.claude/settings.json ~/.claude/settings.json
ln -s ~/dotfiles/.claude/CLAUDE.md ~/.claude/CLAUDE.md
```
