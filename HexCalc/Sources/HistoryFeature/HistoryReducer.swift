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
            case selectionChanged(HistoryItem.ID?)
            case selectionConfirmed(HistoryItem.ID)
            case itemDeleted(HistoryItem.ID)
        }
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.mainQueue) var mainQueue

    enum CancelID { case returnKey, deleteKey }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.selection):
                return .send(.delegate(.selectionChanged(state.selection)))

            case .binding:
                return .none

            case .delegate:
                return .none

            case .returnKeyPressed:
                return .run { [selection = state.selection] send in
                    if let selection {
                        await send(.delegate(.selectionConfirmed(selection)))
                    }
                    await dismiss()
                }
                .debounce(id: CancelID.returnKey, for: 0.2, scheduler: self.mainQueue)

            case let .historyUpdated(history):
                state.history = history
                return .none

            case .deleteKeyPressed:
                guard let selection = state.selection else { return .none }
                return .send(.delegate(.itemDeleted(selection)))
                    .debounce(id: CancelID.deleteKey, for: 0.2, scheduler: self.mainQueue)
            }
        }
        ._printChanges()
    }
}
