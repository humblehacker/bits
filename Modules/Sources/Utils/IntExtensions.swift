import BigInt
import Foundation

public extension FixedWidthInteger {
    var fixedWidthBinaryString: String {
        let zeroPadding = String(repeating: "0", count: leadingZeroBitCount)
        guard self > 0 else { return zeroPadding }
        let binaryString = String(self, radix: 2)
        return zeroPadding + binaryString
    }
}

public extension FixedWidthInteger {
    static var bounds: ClosedRange<Self> {
        min ... max
    }

    static var bigBounds: ClosedRange<BigInt> {
        BigInt(min) ... BigInt(max)
    }
}

public extension BigUInt {
    func fixedWidthBinaryString(_ bitWidth: Int) -> String {
        let binaryString = String(self, radix: 2)
        let zeroPadding = String(repeating: "0", count: bitWidth - binaryString.count)
        return zeroPadding + binaryString
    }
}

public extension BigInt {
    func twosComplement<T: BinaryInteger>() -> T {
        signum() < 0
            ? ~T(magnitude) + 1
            : T(magnitude)
    }
}
