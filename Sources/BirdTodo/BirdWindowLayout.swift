import CoreGraphics

enum BirdCorner {
    case bottomRight
}

enum BirdWindowLayout {
    private static let edgeInset: CGFloat = 24

    static func frame(in screenFrame: CGRect, size: CGSize, corner: BirdCorner) -> CGRect {
        switch corner {
        case .bottomRight:
            return CGRect(
                x: screenFrame.maxX - size.width - edgeInset,
                y: screenFrame.minY + edgeInset,
                width: size.width,
                height: size.height
            )
        }
    }
}
