import ComposableArchitecture
import Dependencies
import Utils

@Reducer
public struct EntryReducer {
    typealias IdentifiedAction = IdentifiedActionOf<Self>

    @ObservableState
    public struct State: Equatable, Identifiable {
        let kind: EntryKind
        var text: String
        var binText: BinaryTextFieldReducer.State?
        var value: Int
        var isFocused: Bool

        public var id: EntryKind { kind }
        var title: String { kind.title }

        public init(
            _ kind: EntryKind,
            text: String = "",
            binText: BinaryTextFieldReducer.State? = nil,
            value: Int = 0,
            isFocused: Bool = false
        ) {
            self.kind = kind
            self.text = text
            self.binText = binText
            self.value = value
            self.isFocused = isFocused
        }

        mutating func updateValue(_ value: Int) -> Effect<IdentifiedAction> {
            guard value != self.value else { return .none }
            return .send(.element(id: id, action: .binding(.set(\.value, value))))
        }

        mutating func updateText(_ text: String) -> Effect<IdentifiedAction> {
            guard text != self.text else { return .none }
            return .send(.element(id: id, action: .binding(.set(\.text, text))))
        }

        mutating func updateBitWidth( _ bitWidth: Bits) -> Effect<IdentifiedAction> {
            guard let binText else { return .none }
            guard bitWidth != binText.bitWidth else { return .none }
            return .send(.element(id: id, action: .binText(.binding(.set(\.bitWidth, bitWidth)))))
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case binText(BinaryTextFieldReducer.Action)
        case confirmationKeyPressed
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable {
            case valueUpdated(Int)
            case focusChanged(EntryKind)
        }
    }

    @Dependency(\.entryConverter) var entryConverter

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in reduce(state: &state, action: action) }
            .ifLet(\.binText, action: \.binText) { BinaryTextFieldReducer() }
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

            case .binText:
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

extension EntryKind {
    var title: String {
        switch self {
        case .exp: "exp"
        case .bin: "BIN"
        case .dec: "DEC"
        case .hex: "HEX"
        }
    }
}

extension EntryKind {
    var base: Int {
        switch self {
        case .exp: 10
        case .bin: 2
        case .dec: 10
        case .hex: 16
        }
    }
}
