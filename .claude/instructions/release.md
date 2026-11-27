# Releases

Release only when the user asks. Publishing, tags, and GitHub releases are never part of a normal commit.

## Before a release

- Pick the version. The project follows Semantic Versioning. Below 1.0.0, a minor version can contain breaking changes,
  so a new feature or a behavior change bumps the minor version and a fix or README-only change bumps the patch.
- Check that every version badge in `docs/` that says `Added in`, `Changed in`, or `Removed in` the next version matches
  the version you are about to set. The badges are written ahead of time, so they can disagree with `ember.toml`.
- Check what the package ships with `embr publish --dry-run`. `includes` in `ember.toml` lists the published files, and
  it ships raw `src/`. That only works while `src/` requires its dependencies with relative paths, as described in
  [requires.md](requires.md). Shipping `dist/` would not help, because Larvae rewrites the requires to
  `@game/ReplicatedStorage/...`, which does not exist in a consumer's game.
- Test the install with `embr publish --local` and a scratch project, as described in [requires.md](requires.md).
- Run every check in [larvae-checks.md](larvae-checks.md) and [testing.md](testing.md).

## Keeping the version current

The user allowed Claude to update the version while a release is being developed, because it is necessary. Keep `version` in
`ember.toml` at the next version, and name the open changelog section `## [<version>] - Unreleased`, with the version in the
`Added in` badges matching. Change them whenever the next version changes, for example when a breaking change turns a patch
into a minor. This does not publish, tag, or push `main`.

## Steps

1. Check that `version` in `ember.toml` is the version being released.
2. In `CHANGELOG.md`, change `## [<version>] - Unreleased` to `## [<version>] - <YYYY-MM-DD>` and add a new empty
   `## [Unreleased]` above it.
3. Commit as `chore: release <version>` on `dev`, then push it as described in [git.md](git.md).
4. Publish to Ember, tag `v<version>`, and create the GitHub release with the changelog entry as its notes.
5. Tell the user which version was released.

A published version is immutable. A README change only reaches the Ember page in a new version.

## Docs site

The docs site deploys from `main` only (`.github/workflows/deploy-docs.yml`). Changes on `dev` do not appear on the
site until `main` is updated.
