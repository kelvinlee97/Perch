import Foundation
import Testing
@testable import Perch

@Suite("Localization")
struct LocalizationTests {
    /// Every string the app asks for must have English text, otherwise an English
    /// system shows the Chinese source string.
    @Test("Every localized string has English text")
    func everyKeyHasEnglishText() throws {
        let used = try keysUsedInSources()
        #expect(!used.isEmpty)

        let missing = used.subtracting(try englishTranslations().keys)
        #expect(missing.isEmpty, "Missing English text for: \(missing.sorted().joined(separator: ", "))")
    }

    @Test("English text has no stale entries")
    func englishTextIsNotStale() throws {
        let unused = Set(try englishTranslations().keys).subtracting(try keysUsedInSources())
        #expect(unused.isEmpty, "English text without a matching string: \(unused.sorted().joined(separator: ", "))")
    }

    /// A key missing from Chinese falls back to English on a Chinese system, so
    /// the two files have to cover the same strings.
    @Test("Chinese text covers the same strings as English")
    func chineseCoversEnglish() throws {
        let english = try translations(in: "en")
        let chinese = try translations(in: "zh-Hans")
        let missing = Set(english.keys).subtracting(chinese.keys)
        #expect(missing.isEmpty, "Missing Chinese text for: \(missing.sorted().joined(separator: ", "))")
    }

    @Test("Localizable.strings ships with the app resources")
    func stringsFileIsBundled() throws {
        let path = try #require(
            Bundle.module.path(forResource: "Localizable", ofType: "strings"),
            "Localizable.strings is missing from the resource bundle"
        )
        let contents = try String(contentsOfFile: path, encoding: .utf8)
        #expect(contents.contains("\"打开 Perch\" = \"Open Perch\";"))
    }
}

private let sourceDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("Sources/Perch")

private func keysUsedInSources() throws -> Set<String> {
    let files = try FileManager.default
        .contentsOfDirectory(at: sourceDirectory, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "swift" }

    var keys = Set<String>()
    for file in files {
        let source = try String(contentsOf: file, encoding: .utf8)
        for segment in source.components(separatedBy: "perchLocalized(\"").dropFirst() {
            guard let end = segment.firstIndex(of: "\"") else { continue }
            keys.insert(String(segment[segment.startIndex..<end]))
        }
    }
    return keys
}

private func englishTranslations() throws -> [String: String] {
    try translations(in: "en")
}

private func translations(in localization: String) throws -> [String: String] {
    let url = sourceDirectory.appendingPathComponent("Resources/\(localization).lproj/Localizable.strings")
    let contents = try String(contentsOf: url, encoding: .utf8)

    var translations: [String: String] = [:]
    for line in contents.split(separator: "\n") {
        // `"key" = "value";` splits into ["", key, " = ", value, ";"].
        let parts = line.split(separator: "\"", omittingEmptySubsequences: false)
        guard parts.count == 5, parts[2].contains("=") else { continue }
        translations[String(parts[1])] = String(parts[3])
    }
    return translations
}
