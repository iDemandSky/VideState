# Releases

Release only when the user asks. Publishing, tags, and GitHub releases are never part of a normal commit.

## Before a release

- Pick the version. The project follows Semantic Versioning. Below 1.0.0, a minor version can contain breaking changes,
  so a new feature or a behavior change bumps the minor version and a fix or README-only change bumps the patch.
- Check that every version badge in `docs/` that says `Added in`, `Changed in`, or `Removed in` the next version matches
  the version you are about to set. The badges are written ahead of time, so they can disagree with `ember.toml`.
- Check what the package ships. `includes` in `ember.toml` lists the published files. Source in `src/` requires
  dependencies through aliases that only `larvae process` rewrites, so a package that ships raw `src/` may break on
  install. Confirm what consumers receive before publishing, and tell the user if it ships unprocessed code.
- Run every check in [larvae-checks.md](larvae-checks.md) and [testing.md](testing.md).

## Steps

1. Set `version` in `ember.toml`.
2. In `CHANGELOG.md`, rename `## [Unreleased]` to `## [<version>] - <YYYY-MM-DD>` and add a new empty
   `## [Unreleased]` above it.
3. Commit as `chore: release <version>` on `dev`, then push it as described in [git.md](git.md).
4. Publish to Ember, tag `v<version>`, and create the GitHub release with the changelog entry as its notes.
5. Tell the user which version was released.

A published version is immutable. A README change only reaches the Ember page in a new version.

## Docs site

The docs site deploys from `main` only (`.github/workflows/deploy-docs.yml`). Changes on `dev` do not appear on the
site until `main` is updated.
