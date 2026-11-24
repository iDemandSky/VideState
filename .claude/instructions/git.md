# Git

Git workflow follows the global rules in `~/.claude/CLAUDE.md`: commit to `dev` after each feature change, with
Conventional Commits.

Push `dev` only. Never push to `main` in this repo: the user syncs `main` manually. This overrides the older rule that
synced `main` after every push. Publishing to Ember, tags, and releases still happen only when the user asks.
