# Migrating a dotfile to stow

1. Move the file from `~/.config/<app>/file` into
   `opencode/.config/<app>/file` (or the appropriate subdirectory)
2. Back up the original: `cp ~/.config/<app>/file ~/.config/<app>/file.bak`
3. Remove the original: `rm ~/.config/<app>/file`
4. Stow: `make stow` to create the symlink
5. Verify: `ls -la ~/.config/<app>/file` shows a symlink into the repo
6. Remove the backup once everything works
7. Add the new path to `CFG_DIRS` in the Makefile if the app is new
