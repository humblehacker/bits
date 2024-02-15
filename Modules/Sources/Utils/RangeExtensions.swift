import Foundation

public extension Range where Bound == Int {
    func mid(rounding rule: FloatingPointRoundingRule) -> Int {
        let midValue = Double(lowerBound + upperBound - 1) / 2
        return Int(midValue.rounded(rule))
    }

    var closed: ClosedRange<Int> {
        lowerBound ... (upperBound - 1)
    }
}

public extension ClosedRange where Bound == Int {
    var open: Range<Int> {
        lowerBound ..< (upperBound + 1)
    }
}

infix operator ..<+ : RangeFormationPrecedence

public func ..<+ <Bound: Numeric> (lhs: Bound, rhs: Bound) -> Range<Bound> {
    return lhs ..< lhs + rhs
}
