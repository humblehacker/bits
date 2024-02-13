import Foundation
import IdentifiedCollections

enum BitValue: Character {
    case zero = "0"
    case one = "1"
}

extension BitValue: CustomStringConvertible {
    var description: String {
        String(rawValue)
    }
}

public struct BinaryDigit: Equatable {
    let index: Int
    let value: BitValue
}

extension BinaryDigit: Identifiable {
    public var id: Int { index }
}

extension BinaryDigit {
    init(index: Int, value: Character) {
        self.index = index
        self.value = BitValue(rawValue: value)!
    }
}

extension IdentifiedArrayOf<BinaryDigit> {
    static func zero(bitWidth: Int) -> Self {
        IdentifiedArray(uniqueElements: (0 ..< bitWidth).map { BinaryDigit(index: $0, value: .zero) })
    }
}

