# README and docs site

- The README is a short introduction: the description, the documentation link, the warning, the install command, and
  the license. Guides, API details, and examples go on the docs site, not in the README.
- The README is what Ember and GitHub show. Ember does not render GitHub alerts, so `> [!WARNING]` appears as plain text
  there. Write a warning as a plain blockquote instead:
  ```md
  > **⚠️ Warning**
  >
  > The message.
  ```
- Keep a link's text to the name itself. Write `` [`onTransition`](#handleroptions) option ``, not
  `` [`onTransition` option](#handleroptions) ``, because the code and the plain word render in different formats.
- The docs site deploys from `main` only. See [release.md](release.md).
