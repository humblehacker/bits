import ComposableArchitecture
import Dependencies

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
        case historyInvoked
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate {
            case replaceEvaluatedExpression
        }
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .historyInvoked:
                state.destination = .history(HistoryReducer.State())
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
