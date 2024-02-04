import Foundation

enum BinaryDigit: Character {
    case zero = "0"
    case one = "1"
}

extension BinaryDigit: CustomStringConvertible {
    var description: String {
        String(rawValue)
    }
}

public struct BinaryDigitState: Equatable {
    let index: Int
    let value: BinaryDigit
}

extension BinaryDigitState {
    init(index: Int, value: Character) {
        self.index = index
        self.value = BinaryDigit(rawValue: value)!
    }
}

extension Array<BinaryDigitState> {
    static func zero(bitWidth: Int) -> Self {
        (1 ... bitWidth).map { BinaryDigitState(index: $0, value: .zero) }
    }
}

