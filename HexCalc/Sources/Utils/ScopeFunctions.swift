import Foundation

public extension Equatable {
    @discardableResult mutating
    func apply(_ block: (inout Self) -> Void) -> Self {
        block(&self)
        return self
    }

    func with(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}
