# Releasing Perch

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
