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

struct BinaryDigitState: Equatable {
    let index: Int
    let value: BinaryDigit
}

extension BinaryDigitState {
    init(index: Int, value: Character) {
        self.index = index
        self.value = BinaryDigit(rawValue: value)!
    }
}

