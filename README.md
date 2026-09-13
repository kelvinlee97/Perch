<p align="center">
  <img src="./docs/images/perch-idle.png" width="160" alt="Perch, a small green desktop bird waiting in the corner of the screen" />
</p>

<h1 align="center">Perch</h1>

<p align="center">
  <strong>A small bird for the things on your mind.</strong><br />
  Click to capture a task, pick a reminder, and get back to your day.
</p>

<p align="center">
  Early preview · macOS 14+<br />
  <a href="#build-for-mac">Build for Mac</a> ·
  <a href="./web/README.md">Web setup</a> ·
  <a href="./docs/releasing.md">Publishing</a>
</p>

## What it does

- **Capture in seconds.** Click the bird in the corner of your desktop, type the task, and return to what you were doing.
- **One reminder at a time.** When something comes due, the earliest task appears beside the bird and the rest wait in the queue. Complete it, push it to 10 minutes, tonight, or tomorrow, or delete it.
- **Stays on your Mac.** Tasks, reminders, and preferences live in a local JSON store. No account, no sync, no network.

Tasks are organized into Inbox, Today, and Completed. Reminders can be paused from the Perch menu, and common actions have keyboard shortcuts.

## Where your tasks live

> **The Mac app and the web workspace are separate apps with separate data.**
> Mac data stays on your Mac in `~/Library/Application Support/Perch`.
> The [web workspace](./web/README.md) uses its own Supabase account and cloud database.
> They do not sync.

## Status

Perch is an early macOS preview.

Working today: the desktop companion, local task storage, the task workspace, quick scheduling, the single-task due reminder with its complete, defer, and delete actions, first-run guidance, and manual reminder pause.

Not yet: scheduled quiet hours, configurable bird behavior, and a signed, notarized public download.

## Build for Mac

Requirements: macOS 14 or later, an Apple silicon or Intel Mac, and a Swift 6 toolchain.

Choose a bundle identifier you control, then run:

```zsh
PERCH_BUNDLE_ID=com.example.perch zsh Scripts/package-app.zsh
```

That creates and replaces `release/Perch.app`. Open it directly:

```zsh
open release/Perch.app
```

The local build is ad hoc signed so macOS can verify that the bundle is internally consistent, and the script does not install Perch in `/Applications`. Move the app there manually if you want to open it from Spotlight or Launchpad.

## Development

```zsh
swift build
zsh Scripts/test.zsh
```

For the web workspace, see [web/README.md](./web/README.md).

## Publishing

Public releases require full Xcode, an Apple Developer Program membership, a Developer ID Application certificate, and a `notarytool` keychain profile. The signing, notarization, DMG, and Gatekeeper workflow lives in [docs/releasing.md](./docs/releasing.md).

## Privacy

The Mac app does not require an account or transmit task or usage data. Read the [privacy policy](./PRIVACY.md) or the [changelog](./CHANGELOG.md). A public support contact will be added before the beta download becomes available.
