import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct ExpressionEvaluator {
    var evaluate: (_ expression: String) throws -> Int
}

extension ExpressionEvaluator: DependencyKey {
    static let liveValue = ExpressionEvaluator(
        evaluate: { return Int($0) ?? 0 }
    )
}

extension DependencyValues {
    var expressionEvaluator: ExpressionEvaluator {
        get { self[ExpressionEvaluator.self] }
        set { self[ExpressionEvaluator.self] = newValue }
    }
}
