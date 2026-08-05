import AppKit
import Testing
@testable import Perch

@Suite("Bird widget")
struct BirdWidgetButtonTests {
    @MainActor
    @Test("Clicking while quiet does not leave the bird scaled down")
    func quietClickDoesNotChangeAppearance() throws {
        let button = BirdWidgetButton(frame: NSRect(x: 0, y: 0, width: 88, height: 88))
        button.isQuietMode = true
        let beforeClick = try renderedPNG(of: button)
        let mouseUp = try #require(NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 1,
            clickCount: 1,
            pressure: 0
        ))

        button.mouseUp(with: mouseUp)

        #expect(try renderedPNG(of: button) == beforeClick)
    }

    @MainActor
    private func renderedPNG(of button: BirdWidgetButton) throws -> Data {
        let representation = try #require(button.bitmapImageRepForCachingDisplay(in: button.bounds))
        button.cacheDisplay(in: button.bounds, to: representation)
        return try #require(representation.representation(using: .png, properties: [:]))
    }
}
