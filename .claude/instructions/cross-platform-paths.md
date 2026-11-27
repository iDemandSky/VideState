# Cross-platform paths

- Write every path in docs, scripts, and config with forward slashes, such as `.larvae/build.project.json`. Backslashes only work on Windows.
- Match the exact case of file and folder names. Linux and macOS are case-sensitive, so `tests/types` and `Tests/types` are different paths.
- Do not hard-code a user folder such as `C:/Users/...` or `~/AppData/...`. Describe the location per OS, or use `~`.
- The dev launcher is `serve.cmd`, which uses Argon and is Windows only. The user chose it over the earlier `serve.sh` and `serve.bat` (Rojo) launchers, which were removed.
