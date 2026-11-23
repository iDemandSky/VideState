# Changelog

All notable changes to VideState are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). While the version is below 1.0.0, a minor
version can contain breaking changes.

## [Unreleased]

### Added

- Initial release.
- Rules with `VideState.rule`, which describe the properties and states of a UI component.
- Handlers created with `new`, which are the instances of a component. They provide `sources`, `currentState`, `setState`, `onChange`, and `onTransition`.
- `onTransition` tweens animatable fields with Ripple and passes the eased `current` value and `alpha` to listeners. Easing, duration, and speed are set per handler and can be Vide sources.
- Schema builders: `boolean`, `integer`, `float`, `string`, `enum`, `optional`, `table`, `record`, `color3`, `udim`, `udim2`, and `vector2`.
- `VideState.Infer` and `VideState.InferRule` to read the Luau type of a schema or a rule.
- `VideState.info` for debugging: `get`, `getAllRulesWithTags`, `getAllTags`, and `ruleHasTag`.
