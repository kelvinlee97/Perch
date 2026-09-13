import Foundation

/// Looks up user-facing text for the system's language.
///
/// Keys are the source strings, so text without a translation keeps its original
/// wording instead of showing a raw key.
func perchLocalized(_ key: String, _ arguments: CVarArg...) -> String {
    let format = NSLocalizedString(key, bundle: perchStringsBundle(), comment: "")
    return arguments.isEmpty ? format : String(format: format, arguments: arguments)
}

private func perchStringsBundle() -> Bundle {
    // Packaged apps keep the .lproj folders in Contents/Resources; SwiftPM builds
    // keep them in the target's resource bundle.
    if Bundle.main.path(forResource: "Localizable", ofType: "strings") != nil {
        return .main
    }
    return .module
}
