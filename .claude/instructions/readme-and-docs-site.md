# README and docs site

- The README is an introduction: the description, the documentation link, the warning, a feature list, the install
  command, a short quick start, and the license. The user wants the Ember page to be detailed, so keep the feature list
  in step with the features. Guides, full API details, and the other examples go on the docs site.
- The README is what Ember and GitHub show. Ember does not render GitHub alerts, so `> [!WARNING]` appears as plain text
  there. Write a warning as a plain blockquote instead:
  ```md
  > **⚠️ Warning**
  >
  > The message.
  ```
- Keep a link's text to the name itself. Write `` [`tweenDefault`](#transitionoptions) setting ``, not
  `` [`tweenDefault` setting](#transitionoptions) ``, because the code and the plain word render in different formats.
- The docs site deploys from `main` only. See [release.md](release.md).
