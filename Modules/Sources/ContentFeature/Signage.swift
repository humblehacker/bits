import Foundation

public enum Signage: Equatable {
    case signed
    case unsigned

    public func toggled() -> Signage {
        switch self {
        case .unsigned: .signed
        case .signed: .unsigned
        }
    }
}
