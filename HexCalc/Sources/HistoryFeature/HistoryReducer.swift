import ComposableArchitecture
import Dependencies

@Reducer
public struct HistoryReducer {
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        var history: [HistoryItem] = []

        public init(history: [HistoryItem]) {
            self.history = history
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case historySelected
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .binding(\.history):
                return .none

            case .binding:
                return .none

            case .historySelected:
                return .run { _ in await dismiss() }
            }
        }
    }
}
