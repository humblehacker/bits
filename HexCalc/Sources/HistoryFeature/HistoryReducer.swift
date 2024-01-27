import ComposableArchitecture
import DataStore
import Dependencies

@Reducer
public struct HistoryReducer {
    @ObservableState
    public struct State: Equatable {
        var history: [HistoryItem] = []
        var selection: HistoryItem.ID?

        public init(history: [HistoryItem] = []) {
            self.history = history
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case returnKeyPressed
        case historyUpdated([HistoryItem])
        case deleteKeyPressed
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case historySelected(HistoryItem)
        }
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.historyStore) var historyStore
    @Dependency(\.mainQueue) var mainQueue

    enum CancelID { case returnKey, deleteKey }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.history):
                return .none

            case .binding:
                return .none

            case .delegate:
                return .none

            case .returnKeyPressed:
                return .run { [selection = state.selection] send in
                    if let selection {
                        if let item = try await historyStore.item(id: selection) {
                            await send(.delegate(.historySelected(item)))
                        }
                    }
                    await dismiss()
                }
                .debounce(id: CancelID.returnKey, for: 0.2, scheduler: self.mainQueue)

            case let .historyUpdated(history):
                state.history = history
                return .none

            case .deleteKeyPressed:
                guard let selection = state.selection else { return .none }
                return .run { send in
                    try await historyStore.removeItem(selection)
                    let history = try await historyStore.items()
                    await send(.historyUpdated(history))
                    if history.isEmpty {
                        await dismiss()
                    }
                }
                .debounce(id: CancelID.deleteKey, for: 0.2, scheduler: self.mainQueue)
            }
        }
        ._printChanges()
    }
}
