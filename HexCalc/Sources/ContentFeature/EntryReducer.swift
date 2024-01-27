import ComposableArchitecture
import DataStore
import Dependencies
import HistoryFeature
import Utils

@Reducer
public struct EntryReducer {
    @ObservableState
    public struct State {
        let kind: FocusedField
        var showHistory: Bool
        var text: String
        var focusedField: FocusedField?
        @Presents var destination: Destination.State?

        var title: String {
            switch kind {
            case .exp: "exp"
            case .bin: "BIN"
            case .dec: "DEC"
            case .hex: "HEX"
            }
        }

        public init(kind: FocusedField) {
            self.kind = kind
            showHistory = false
            text = ""
            focusedField = nil
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case upArrowPressed
        case historyLoaded([HistoryItem])
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate {
            case confirmationKeyPressed
        }
    }

    @Dependency(\.historyStore) var historyStore
    @Dependency(\.mainQueue) var mainQueue

    enum CancelID { case upArrow }

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .upArrowPressed:
                return .run { send in
                    let history = try await historyStore.items()
                    guard history.isNotEmpty else { return }
                    await send(.historyLoaded(history))
                }
                .debounce(id: CancelID.upArrow, for: 0.2, scheduler: self.mainQueue)

            case let .historyLoaded(history):
                guard state.destination == nil else { return .none }
                state.destination = .history(HistoryReducer.State(history: history))
                return .none

            case let .destination(.presented(.history(.delegate(.historySelected(item))))):
                state.text = item.text
                return .none

            case .destination:
                return .none

            case .binding(\.text):
                return .none

            case .binding:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination()
        }
        ._printChanges()
    }

    @Reducer
    public struct Destination {
        @ObservableState
        public enum State {
            case history(HistoryReducer.State)
        }

        public enum Action {
            case history(HistoryReducer.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.history, action: \.history) {
                HistoryReducer()
            }
        }
    }
}
