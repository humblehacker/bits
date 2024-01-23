import ComposableArchitecture
import Dependencies

@Reducer
public struct EntryReducer {
    @ObservableState
    public struct State {
        let kind: FocusedField
        var text: String
        var focusedField: FocusedField?

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
            text = ""
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate {
            case replaceEvaluatedExpression
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
    }
}
