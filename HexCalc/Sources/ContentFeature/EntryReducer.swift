import ComposableArchitecture
import Dependencies
import Utils

@Reducer
public struct EntryReducer {
    @ObservableState
    public struct State {
        let kind: FocusedField
        var showHistory: Bool
        var text: String
        var focusedField: FocusedField?
        var width: Double

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
            width = 100
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate {
            case confirmationKeyPressed
        }
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .binding(\.text):
                return .none

            case .binding:
                return .none

            case .delegate:
                return .none
            }
        }
        ._printChanges()
    }
}
