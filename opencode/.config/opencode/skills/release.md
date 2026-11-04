# Release workflow

1. `git pull --rebase` to catch up with remote
2. `make doctor` to verify everything is healthy
3. `git diff --stat` to review staged/unstaged changes
4. Commit changes with a descriptive message
5. `make push` to push (runs checks first)
6. Tag the release: `git tag v<major>.<minor>.<patch> && git push --tags`
