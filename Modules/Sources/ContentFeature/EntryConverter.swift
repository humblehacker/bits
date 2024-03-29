import BigInt
import Dependencies
import DependenciesMacros
import Foundation
import Types
import Utils

@DependencyClient
struct EntryConverter {
    var text: (_ value: EntryValue, _ kind: EntryKind) throws -> String = { _, _ in "" }
    var value: (_ text: String, _ kind: EntryKind, _ bits: Bits, _ signage: Signage) throws -> EntryValue? = { _, _, _, _ in nil }
}

enum EntryConverterError: Error {
    case invalidConversion
    case valueOutOfBounds(value: EntryValue, bounds: ClosedRange<BigInt>)
}

extension EntryConverter: DependencyKey {
    static let liveValue = Self(
        text: { value, kind in
            // value should have already been validated
            try validateValue(value)

            switch kind {
            case .bin:
                return switch (value.bits, value.signage) {
                case (._8, .unsigned): String(UInt8(value.value), radix: 2)
                case (._8, .signed): String(value.value.twosComplement() as UInt8, radix: 2)
                case (._16, .unsigned): String(UInt16(value.value), radix: 2)
                case (._16, .signed): String(value.value.twosComplement() as UInt16, radix: 2)
                case (._32, .unsigned): String(UInt32(value.value), radix: 2)
                case (._32, .signed): String(value.value.twosComplement() as UInt32, radix: 2)
                case (._64, .unsigned): String(UInt64(value.value), radix: 2)
                case (._64, .signed): String(value.value.twosComplement() as UInt64, radix: 2)
                }

            case .dec, .hex, .exp:
                let result = String(value.value, radix: kind.base, uppercase: true)
                return result
            }
        },
        value: { text, kind, bits, signage in
            switch kind {
            case .exp:
                guard text.isNotEmpty else { return nil }
                @Dependency(\.expressionEvaluator) var expressionEvaluator
                let value = try expressionEvaluator.evaluate(expression: text, bits: bits, signage: signage)
                let entryValue = EntryValue(value, bits: bits, signage: signage)
                try validateValue(entryValue)
                return entryValue

            case .bin, .dec, .hex:
                // When text == "-", value will equal -0 so we filter that out here. Is there a better way?
                guard let value = BigInt(text, radix: kind.base), !(value.isZero && value.sign == .minus)
                else { throw EntryConverterError.invalidConversion }
                let entryValue = EntryValue(value, bits: bits, signage: signage)
                try validateValue(entryValue)
                return entryValue
            }
        }
    )

    static func validateValue(_ value: EntryValue) throws {
        switch (value.bits, value.signage) {
        case (._8, .unsigned): if !UInt8.bigBounds.contains(value.value) {
                throw EntryConverterError.valueOutOfBounds(value: value, bounds: UInt8.bigBounds)
            }
        case (._8, .signed): if !Int8.bigBounds.contains(value.value) {
                throw EntryConverterError.valueOutOfBounds(value: value, bounds: Int8.bigBounds)
            }
        case (._16, .unsigned): if !UInt16.bigBounds.contains(value.value) {
                throw EntryConverterError.valueOutOfBounds(value: value, bounds: UInt16.bigBounds)
            }
        case (._16, .signed): if !Int16.bigBounds.contains(value.value) {
                throw EntryConverterError.valueOutOfBounds(value: value, bounds: Int16.bigBounds)
            }
        case (._32, .unsigned): if !UInt32.bigBounds.contains(value.value) {
                throw EntryConverterError.valueOutOfBounds(value: value, bounds: UInt32.bigBounds)
            }
        case (._32, .signed): if !Int32.bigBounds.contains(value.value) {
                throw EntryConverterError.valueOutOfBounds(value: value, bounds: Int32.bigBounds)
            }
        case (._64, .unsigned): if !UInt64.bigBounds.contains(value.value) {
                throw EntryConverterError.valueOutOfBounds(value: value, bounds: UInt64.bigBounds)
            }
        case (._64, .signed): if !Int64.bigBounds.contains(value.value) {
                throw EntryConverterError.valueOutOfBounds(value: value, bounds: Int64.bigBounds)
            }
        }
    }
}

extension DependencyValues {
    var entryConverter: EntryConverter {
        get { self[EntryConverter.self] }
        set { self[EntryConverter.self] = newValue }
    }
}
