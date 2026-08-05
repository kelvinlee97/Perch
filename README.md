<p align="center">
  <img src="./docs/images/perch-idle.png" width="280" alt="Perch, a small green desktop bird, waiting quietly" />
</p>

<h1 align="center">Perch</h1>

<p align="center">
  <strong>A gentle to-do companion for Mac.</strong><br />
  Capture what matters, keep it close, and focus on one thing at a time.
</p>

## Meet Perch

Perch is a lightweight, local-first to-do app that lives on your Mac as a small desktop bird.

Instead of asking you to maintain another complicated productivity system, Perch gives loose thoughts a quiet place to land. Click the bird, write down a task, and return to what you were doing. When it is time to act, Perch is designed to surface one useful reminder—not an overwhelming wall of notifications.

## The problem it solves

Most to-do apps are excellent at collecting tasks. Over time, though, the list itself can become another source of work:

- Capturing a small thought means opening a full task manager.
- Long lists make everything feel equally urgent.
- Frequent notifications interrupt focus instead of supporting it.
- Cloud accounts and setup add friction to something that should feel immediate.

Perch takes a calmer approach: **make capture effortless, keep tasks local, and bring attention to one thing at a time.**

## A bird that stays out of the way

The bird rests in the corner of your desktop without taking over your workspace. It is a visual anchor for the things you do not want to keep carrying in your head.

## What you can do today

- Capture a task in a few seconds.
- Sort tasks into **Inbox**, **Today**, and **Completed**.
- Choose a quick time: no reminder, 10 minutes, tonight, or tomorrow.
- See the earliest due task beside the bird, with later due tasks kept in the queue.
- Complete, restore, reschedule, or delete tasks.
- Pause reminders immediately from the Perch menu.
- Use keyboard shortcuts for common actions.
- Keep everything on your Mac in a local JSON store.
- Open the workspace from the bird or the menu bar.

## The experience we are building

Perch is guided by a few simple ideas:

1. **One task deserves one moment of attention.** Due tasks should appear one at a time, with the rest waiting quietly.
2. **Capture should not break your flow.** Writing something down should take seconds.
3. **Reminders should feel helpful, not demanding.** Perch should nudge, never nag.
4. **Your personal tasks should stay personal.** The core experience works locally without an account or network service.
5. **Personality can make utility feel lighter.** The bird is not decoration—it reflects the state of your tasks and makes returning to them feel less clinical.

## Project status

Perch is an early macOS MVP under active development.

The desktop companion, local task storage, task workspace, quick scheduling controls, due-reminder queue, core reminder actions, first-run guidance, and manual reminder pause are implemented. Scheduled quiet hours, configurable bird behavior, and release-ready signing and notarization are still in progress.

## Build it locally

### Requirements

- macOS 14 or later
- Apple silicon or Intel Mac
- Swift 6 toolchain
- Full Xcode for eventual Developer ID signing and notarization

Choose a bundle identifier you control, then run:

```zsh
PERCH_BUNDLE_ID=com.example.perch zsh Scripts/package-app.zsh
```

The script creates or replaces:

```text
release/Perch.app
```

Open the local build directly:

```zsh
open release/Perch.app
```

To build and open Perch in one step:

```zsh
PERCH_BUNDLE_ID=com.example.perch zsh Scripts/package-app.zsh && open release/Perch.app
```

Run the automated checks with:

```zsh
zsh Scripts/test.zsh
```

The script does not install Perch in `/Applications`. Move the app there manually if you want to open it from Spotlight or Launchpad. The local build is ad hoc signed so macOS can verify that the bundle is internally consistent.

> [!NOTE]
> This build is intended for local development and testing. It is not yet Developer ID-signed or notarized for public distribution.

## Create a public release

Public releases require full Xcode, an Apple Developer Program membership, a Developer ID Application certificate, and a `notarytool` keychain profile.

Store the notarization credentials once:

```zsh
xcrun notarytool store-credentials "perch-notary"
```

Then create the signed, notarized, and stapled disk image:

```zsh
PERCH_BUNDLE_ID=ink.example.perch \
PERCH_VERSION=0.1.0 \
PERCH_BUILD_NUMBER=1 \
CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE=perch-notary \
zsh Scripts/package-release.zsh
```

The release script builds a Universal Binary for Apple silicon and Intel Macs, then verifies the Developer ID signature, hardened runtime, secure timestamp, notarization ticket, mounted app, and Gatekeeper assessment before replacing:

```text
release/Perch.dmg
```

It refuses to create a public release with an ad hoc identity or while Command Line Tools is selected instead of full Xcode.

After uploading the DMG, download it again with Safari or another browser and verify that exact downloaded file:

```zsh
PERCH_BUNDLE_ID=ink.example.perch \
PERCH_VERSION=0.1.0 \
PERCH_BUILD_NUMBER=1 \
PERCH_TEAM_ID=TEAMID \
zsh Scripts/verify-downloaded-release.zsh ~/Downloads/Perch.dmg
```

This check requires browser quarantine metadata and verifies the stapled ticket, mounted app, exact Apple Developer team, bundle ID, version, build number, hardened runtime, secure timestamp, Gatekeeper assessment, and architecture without copying anything into `/Applications`.

See Apple's guides for [distributing macOS software](https://developer.apple.com/macos/distribution/) and [notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Privacy and support

Perch does not require an account or transmit task and usage data. Read the [privacy policy](./PRIVACY.md) or review the [changelog](./CHANGELOG.md). A public support contact will be added before the beta download becomes available.
