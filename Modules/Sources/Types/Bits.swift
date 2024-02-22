import Foundation

public enum Bits: Int, Equatable, CaseIterable, Identifiable {
    case _8 = 8
    case _16 = 16
    case _32 = 32
    case _64 = 64

    public var id: Int { rawValue }
}
