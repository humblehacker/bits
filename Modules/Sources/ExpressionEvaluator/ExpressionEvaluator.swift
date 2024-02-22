import BigInt
import Dependencies
import DependenciesMacros
import Foundation
import Types

@DependencyClient
public struct ExpressionEvaluator {
    public var evaluate: (_ expression: String, _ bits: Bits, _ signage: Signage) throws -> BigInt
}

extension ExpressionEvaluator: DependencyKey {
    public static let liveValue = ExpressionEvaluator(
        evaluate: { expression, bits, signage in
            switch (bits, signage) {
            case (._8, .unsigned): try BigInt(ExpressionParser<UInt8>().parse(expression))
            case (._8, .signed): try BigInt(ExpressionParser<Int8>().parse(expression))
            case (._16, .unsigned): try BigInt(ExpressionParser<UInt16>().parse(expression))
            case (._16, .signed): try BigInt(ExpressionParser<Int16>().parse(expression))
            case (._32, .unsigned): try BigInt(ExpressionParser<UInt32>().parse(expression))
            case (._32, .signed): try BigInt(ExpressionParser<Int32>().parse(expression))
            case (._64, .unsigned): try BigInt(ExpressionParser<UInt64>().parse(expression))
            case (._64, .signed): try BigInt(ExpressionParser<Int64>().parse(expression))
            }
        }
    )
}

extension ExpressionEvaluator: TestDependencyKey {
    public static let testValue = liveValue
}

public extension DependencyValues {
    var expressionEvaluator: ExpressionEvaluator {
        get { self[ExpressionEvaluator.self] }
        set { self[ExpressionEvaluator.self] = newValue }
    }
}
