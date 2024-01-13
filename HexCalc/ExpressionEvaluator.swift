import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct ExpressionEvaluator {
    var evaluate: (_ expression: String) throws -> Int
}

extension ExpressionEvaluator: DependencyKey {
    static let liveValue = ExpressionEvaluator(
        evaluate: { expression in
            let parser = ExpressionParser()
            return try parser.parse(expression)
        }
    )
}

extension DependencyValues {
    var expressionEvaluator: ExpressionEvaluator {
        get { self[ExpressionEvaluator.self] }
        set { self[ExpressionEvaluator.self] = newValue }
    }
}
