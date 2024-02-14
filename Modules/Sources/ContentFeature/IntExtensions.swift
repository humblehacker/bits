import Foundation

extension Int {
    func paddedBinaryString(bits: Int, blockSize: Int = 4) -> String {
        let binaryString = String(self, radix: 2)
        let paddedString = String(repeating: "0", count: Swift.max(0, bits - binaryString.count)) + binaryString
        guard blockSize > 0 else { return paddedString }
        var result = ""
        for (index, char) in paddedString.enumerated() {
            if index % blockSize == 0 && index != 0 {
                result += " "
            }
            result += String(char)
        }
        return result
    }
}
