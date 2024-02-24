import CoreGraphics

public extension CGPoint {
    func with(x: Double? = nil, y: Double? = nil) -> CGPoint {
        return CGPoint(x: x ?? self.x, y: y ?? self.y)
    }
}

public extension CGSize {
    func with(width: Double? = nil, height: Double? = nil) -> CGSize {
        return CGSize(width: width ?? self.width, height: height ?? self.height)
    }

    func adjusted(dWidth: Double = 0, dHeight: Double = 0) -> CGSize {
        return CGSize(width: width + dWidth, height: height + dHeight)
    }
}

public extension CGRect {
    func with(origin: CGPoint? = nil, size: CGSize? = nil) -> CGRect {
        return CGRect(origin: origin ?? self.origin, size: size ?? self.size)
    }

    func with(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil) -> CGRect {
        return CGRect(x: x ?? minX, y: y ?? minY, width: width ?? self.width, height: height ?? self.height)
    }
}
