# Contributing to Market Invoices

Thank you for your interest in contributing! Whether you want to fix a bug, improve the UI, add documentation, or propose a new feature, your help is welcome.

## How to contribute

1. **Fork** the repository on GitHub
2. **Clone** your fork locally
3. Create a **feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. Make your changes and keep them focused
5. Run checks before opening a PR:
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   ```
6. **Commit** with a clear message describing *why* the change was made
7. **Push** to your fork and open a **Pull Request** against `main`
8. Describe what changed, how to test it, and include screenshots for UI updates

## What you can contribute

- Bug fixes and performance improvements
- UI/UX enhancements (especially accessibility and layout)
- Documentation and translations
- Tests for existing behavior
- Printer or device compatibility improvements

## Reporting issues

Open a [GitHub Issue](https://github.com/mathyc0de/market-invoices-app/issues) with:

- Steps to reproduce the problem
- Expected vs. actual behavior
- Device model, Android version, and app version
- Screenshots or logs when relevant

## Code guidelines

- Match existing code style and naming conventions
- Prefer small, focused changes over large refactors
- Avoid changing business logic unless the issue or feature explicitly requires it
- Do not commit secrets (`.env`, API keys, credentials)

## Development setup

See the [README](README.md#build--install) for prerequisites, environment configuration, and build instructions.
