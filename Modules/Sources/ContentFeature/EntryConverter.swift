import BigInt
import Dependencies
import DependenciesMacros
import Foundation
import Utils

@DependencyClient
struct EntryConverter {
    var text: (_ bigint: BigInt, _ kind: EntryKind, _ bits: Bits, _ signage: Signage) throws -> String = { _, _, _, _ in "" }
    var integer: (_ text: String, _ kind: EntryKind, _ bits: Bits, _ signage: Signage) throws -> BigInt? = { _, _, _, _ in 0 }
}

enum EntryConverterError: Error {
    case invalidConversion
    case overflow
}

extension EntryConverter: DependencyKey {
    static let liveValue = Self(
        text: { bigint, kind, bits, signage in
            // value should have already been validated
            try validateValue(bigint, bits: bits, signage: signage)

            switch kind {
            case .bin:
                return switch (bits, signage) {
                case (._8, .unsigned): String(UInt8(bigint), radix: 2)
                case (._8, .signed): String(bigint.twosComplement() as UInt8, radix: 2)
                case (._16, .unsigned): String(UInt16(bigint), radix: 2)
                case (._16, .signed): String(bigint.twosComplement() as UInt16, radix: 2)
                case (._32, .unsigned): String(UInt32(bigint), radix: 2)
                case (._32, .signed): String(bigint.twosComplement() as UInt32, radix: 2)
                case (._64, .unsigned): String(UInt64(bigint), radix: 2)
                case (._64, .signed): String(bigint.twosComplement() as UInt64, radix: 2)
                }

            case .dec, .hex, .exp:
                let result = String(bigint, radix: kind.base)
                return result
            }
        },
        integer: { text, kind, bits, signage in
            switch kind {
            case .exp:
                guard text.isNotEmpty else { return nil }
                @Dependency(\.expressionEvaluator.evaluate) var evaluateExpression
                let value = try BigInt(evaluateExpression(text))
                try validateValue(value, bits: bits, signage: signage)
                return value

            case .bin, .dec, .hex:
                // When text == "-", value will equal -0 so we filter that out here. Is there a better way?
                guard let value = BigInt(text, radix: kind.base), !(value.isZero && value.sign == .minus)
                else { throw EntryConverterError.invalidConversion }
                try validateValue(value, bits: bits, signage: signage)
                return value
            }
        }
    )

    static func validateValue(_ value: BigInt, bits: Bits, signage: Signage) throws {
        switch (bits, signage) {
        case (._8, .unsigned): if !UInt8.bigBounds.contains(value) { throw EntryConverterError.overflow }
        case (._8, .signed): if !Int8.bigBounds.contains(value) { throw EntryConverterError.overflow }
        case (._16, .unsigned): if !UInt16.bigBounds.contains(value) { throw EntryConverterError.overflow }
        case (._16, .signed): if !Int16.bigBounds.contains(value) { throw EntryConverterError.overflow }
        case (._32, .unsigned): if !UInt32.bigBounds.contains(value) { throw EntryConverterError.overflow }
        case (._32, .signed): if !Int32.bigBounds.contains(value) { throw EntryConverterError.overflow }
        case (._64, .unsigned): if !UInt64.bigBounds.contains(value) { throw EntryConverterError.overflow }
        case (._64, .signed): if !Int64.bigBounds.contains(value) { throw EntryConverterError.overflow }
        }
    }
}

extension DependencyValues {
    var entryConverter: EntryConverter {
        get { self[EntryConverter.self] }
        set { self[EntryConverter.self] = newValue }
    }
}
