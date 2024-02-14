import Foundation

public extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

public extension Int {
    func clamped(to limits: Range<Self>) -> Self {
        return Swift.min(Swift.max(self, limits.lowerBound), limits.upperBound - 1)
    }
}
