import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct EntryConverter {
    var text: (_ integer: Int, _ kind: FocusedField) throws -> String = { _, _ in "" }
    var integer: (_ text: String, _ kind: FocusedField) throws -> Int? = { _, _ in 0 }
}

extension EntryConverter: DependencyKey {
    static let liveValue = Self(
        text: { integer, kind in
            String(integer, radix: kind.base, uppercase: true)
        },
        integer: { text, kind in
            if kind == .exp {
                @Dependency(\.expressionEvaluator.evaluate) var evaluateExpression
                return try evaluateExpression(text)
            } else {
                return Int(text, radix: kind.base)
            }
        }
    )
}

extension DependencyValues {
    var entryConverter: EntryConverter {
        get { self[EntryConverter.self] }
        set { self[EntryConverter.self] = newValue }
    }
}
