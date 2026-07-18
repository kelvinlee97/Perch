# Bird Todo

Bird Todo is a lightweight macOS desktop companion for recording to-dos and surfacing one gentle reminder at a time.

## Build a local app bundle

The project needs macOS and the Swift toolchain. Choose a bundle identifier you control, then run:

```zsh
BIRD_TODO_BUNDLE_ID=com.example.birdtodo zsh Scripts/package-app.zsh
```

This creates `release/BirdTodo.app`. The build performs an ad hoc signature so Finder can verify that the bundle is internally consistent. Open it from Finder or move it to `/Applications` for local use.

The generated bundle is for local testing only. It is not Developer ID-signed or notarized, so it is not yet suitable for public download.

## Public release prerequisites

1. Install full Xcode and join the Apple Developer Program.
2. Sign the app with a Developer ID Application certificate and enable the hardened runtime.
3. Submit the signed app or its distribution container to Apple’s notary service.
4. Staple Apple’s notarization ticket, package the app as a `.dmg`, and upload it to the Bird Todo website.

Apple’s distribution guidance: https://developer.apple.com/macos/distribution/

Apple’s notarization guidance: https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
