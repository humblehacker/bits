import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct ExpressionEvaluator {
    public var evaluate: (_ expression: String) throws -> Int
}

extension ExpressionEvaluator: DependencyKey {
    public static let liveValue = ExpressionEvaluator(
        evaluate: { expression in
            let parser = ExpressionParser()
            return try parser.parse(expression)
        }
    )
}

extension DependencyValues {
    public var expressionEvaluator: ExpressionEvaluator {
        get { self[ExpressionEvaluator.self] }
        set { self[ExpressionEvaluator.self] = newValue }
    }
}
