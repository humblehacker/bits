import Foundation

enum BitValue: Character {
    case zero = "0"
    case one = "1"
}

extension BitValue: CustomStringConvertible {
    var description: String {
        String(rawValue)
    }
}

public struct BinaryDigitState: Equatable {
    let index: Int
    let value: BitValue
}

extension BinaryDigitState {
    init(index: Int, value: Character) {
        self.index = index
        self.value = BitValue(rawValue: value)!
    }
}

extension Array<BinaryDigitState> {
    static func zero(bitWidth: Int) -> Self {
        (0 ..< bitWidth).map { BinaryDigitState(index: $0, value: .zero) }
    }
}

