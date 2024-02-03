import ComposableArchitecture
import Dependencies
import Utils

@Reducer
public struct EntryReducer {
    typealias IdentifiedAction = IdentifiedActionOf<Self>

    @ObservableState
    public struct State: Equatable, Identifiable {
        let kind: FocusedField
        var text: String
        var value: Int
        var isFocused: Bool

        public var id: String { String(describing: kind) }
        var title: String { kind.title }

        public init(kind: FocusedField) {
            value = 0
            self.kind = kind
            text = ""
            isFocused = false
        }

        mutating func updateValue(_ value: Int) -> Effect<IdentifiedAction> {
            guard value != self.value else { return .none }
            self.value = value
            return .send(.element(id: id, action: Action.binding(.set(\.value, value))))
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case confirmationKeyPressed
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable {
            case valueUpdated(Int)
            case focusChanged(FocusedField)
        }
    }

    @Dependency(\.entryConverter) var entryConverter

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            reduce(state: &state, action: action)
        }
        ._printChanges()
    }

    func reduce(state: inout State, action: Action) -> Effect<Action> {
        do {
            switch action {
            case .binding(\.isFocused):
                return .send(.delegate(.focusChanged(state.kind)))

            case .binding(\.text): // text --> value
                let value = try entryConverter.integer(text: state.text, kind: state.kind) ?? 0
                state.value = value
                return .send(.delegate(.valueUpdated(value)))

            case .binding(\.value): // value --> text
                state.text = try entryConverter.text(integer: state.value, kind: state.kind)
                return .none

            case .binding:
                return .none

            case .confirmationKeyPressed:
                state.text = try entryConverter.text(integer: state.value, kind: state.kind)
                return .none

            case .delegate:
                return .none
            }
        } catch {
            print("unhandled error: \(error)")
            return .none
        }
    }
}

extension FocusedField {
    var title: String {
        switch self {
        case .exp: "exp"
        case .bin: "BIN"
        case .dec: "DEC"
        case .hex: "HEX"
        }
    }
}

extension FocusedField {
    var base: Int {
        switch self {
        case .exp: 10
        case .bin: 2
        case .dec: 10
        case .hex: 16
        }
    }
}
