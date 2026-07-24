# Perch Project Instructions

These instructions add Perch-specific context to the global Codex guidance. Do not repeat general engineering principles here.

## Tech Stack

- Perch is a local-first macOS 14+ desktop companion built with Swift 6.
- Prefer existing Swift, SwiftUI, and AppKit patterns.
- Do not add dependencies or architecture layers without explaining why the existing stack cannot meet the requirement cleanly.
- Use four-space indentation, `UpperCamelCase` for types, and `lowerCamelCase` for methods and properties.
- Name a Swift file after its primary type where practical.
- No formatter or linter is currently configured.

## Engineering Preferences

- Make the smallest change that fully solves the requested problem.
- Match the existing style and avoid unrelated refactoring.
- Keep a test only when it is stable, repeatable, protects important behavior, and has durable maintenance value.
- Keep public documentation concise, non-duplicative, and limited to current behavior.
- Report stale material outside the requested scope; do not update or remove it without confirmation.
- Keep generated builds, temporary verification files, logs, screenshots, and `.DS_Store` out of the public repository.

## Commands and Verification

After Swift changes:

```zsh
swift build
zsh Scripts/test.zsh
```

For UI changes, launch Perch and exercise the affected interaction.

After packaging changes:

```zsh
PERCH_BUNDLE_ID=com.example.perch zsh Scripts/package-app.zsh
```

The packaging command creates `release/Perch.app`; it does not install Perch in `/Applications`. Inspect and launch the packaged app when runtime verification is relevant.

For documentation changes, verify every command, feature statement, and screenshot against the current repository and application behavior.

## Delivery and Publishing

- `release/Perch.app` is the canonical local delivery artifact.
- Before publishing, verify the current branch, complete diff, ignored files, remote state, and push URL.
- Use concise Conventional Commit subjects such as `feat:`, `fix:`, `docs:`, or `chore:`.
- Modification approval does not authorize a commit or push.
- Push directly to `origin/main` only when explicitly requested.
- Do not create a branch or pull request unless explicitly requested.
