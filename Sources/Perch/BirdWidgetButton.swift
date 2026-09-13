import AppKit

final class BirdWidgetButton: NSButton {
    private let birdImage = NSImage(
        contentsOf: Bundle.main.url(forResource: "bird-companion", withExtension: "png")
            ?? Bundle.module.url(forResource: "bird-companion", withExtension: "png")!
    )!
    private var trackingArea: NSTrackingArea?
    private var animationTimer: Timer?
    private var phase: CGFloat = 0
    private var isHovering = false
    private var clickPulse: CGFloat = 0
    var isQuietMode = false {
        didSet {
            guard isQuietMode != oldValue else { return }
            if isQuietMode {
                animationTimer?.invalidate()
                animationTimer = nil
                phase = 0
                clickPulse = 0
            } else {
                startAnimation()
            }
            needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isBordered = false
        title = ""
        setAccessibilityLabel(perchLocalized("打开 Perch"))
        startAnimation()
    }

    required init?(coder: NSCoder) { nil }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func updateTrackingAreas() {
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let newTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(newTrackingArea)
        trackingArea = newTrackingArea
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
        NSCursor.pointingHand.push()
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        NSCursor.pop()
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if !isQuietMode {
            clickPulse = 1
        }
        super.mouseUp(with: event)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        defer { context?.restoreGState() }

        let bounce = isQuietMode ? 0 : sin(phase) * 2.2
        let scale = 1.0 + (isHovering ? 0.045 : 0) - clickPulse * 0.08
        let rotation = isQuietMode ? 0 : sin(phase * 2.4) * (isHovering ? 0.025 : 0.008)
        context?.translateBy(x: bounds.midX, y: bounds.midY + bounce)
        context?.rotate(by: rotation)
        context?.scaleBy(x: scale, y: scale)
        context?.translateBy(x: -bounds.midX, y: -bounds.midY)

        let inset: CGFloat = isHovering ? 2 : 4
        birdImage.draw(
            in: bounds.insetBy(dx: inset, dy: inset),
            from: NSRect(origin: .zero, size: birdImage.size),
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: true,
            hints: nil
        )
    }

    private func startAnimation() {
        let timer = Timer(
            timeInterval: 1.0 / 30.0,
            target: self,
            selector: #selector(advanceAnimation),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    @objc private func advanceAnimation() {
        guard !isQuietMode else { return }
        phase += 0.16
        clickPulse = max(0, clickPulse - 0.12)
        needsDisplay = true
    }
}
