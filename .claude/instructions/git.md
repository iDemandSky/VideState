# Git

Git workflow follows the global rules in `~/.claude/CLAUDE.md`: commit to `dev` after each feature change, with
Conventional Commits.

After pushing `dev`, also push it to `main` (`git push origin dev:main`, fast-forward only). Publishing to Ember, tags,
and releases still happen only when the user asks.
