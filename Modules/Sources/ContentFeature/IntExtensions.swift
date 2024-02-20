import Foundation

extension FixedWidthInteger {
    var fixedWidthBinaryString: String {
        let zeroPadding = String(repeating: "0", count: leadingZeroBitCount)
        guard self > 0 else { return zeroPadding }
        let binaryString = String(self, radix: 2)
        return zeroPadding + binaryString
    }
}
