import BigInt
import ComposableArchitecture
import Dependencies
import Types
import Utils

public struct EntryValue: Equatable {
    var value: BigInt
    var bits: Bits
    var signage: Signage

    public init(_ value: BigInt = 0, bits: Bits = ._8, signage: Signage = .unsigned) {
        self.value = value
        self.bits = bits
        self.signage = signage
    }
}

@Reducer
public struct EntryReducer {
    typealias IdentifiedAction = IdentifiedActionOf<Self>

    @ObservableState
    public struct State: Equatable, Identifiable {
        let kind: EntryKind
        var text: String
        var value: EntryValue
        var binText: BinaryTextFieldReducer.State?
        var isFocused: Bool
        var isError: Bool

        public var id: EntryKind { kind }
        var title: String { kind.title }

        public init(
            _ kind: EntryKind,
            text: String = "",
            value: EntryValue = .init(),
            binText: BinaryTextFieldReducer.State? = nil,
            isFocused: Bool = false,
            isError: Bool = false
        ) {
            self.kind = kind
            self.text = text
            self.value = value
            self.binText = binText
            self.isFocused = isFocused
            self.isError = isError
        }

        mutating func updateValue(_ value: EntryValue) -> Effect<IdentifiedAction> {
            guard value != self.value else { return .none }
            binText?.updateBits(value.bits)
            return .send(.element(id: id, action: .binding(.set(\.value, value))))
        }

        mutating func updateText(_ text: String) -> Effect<IdentifiedAction> {
            guard text != self.text else { return .none }
            return .send(.element(id: id, action: .binding(.set(\.text, text))))
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case binText(BinaryTextFieldReducer.Action)
        case confirmationKeyPressed
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable {
            case valueUpdated(EntryValue)
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
                state.isError = false
                guard let value = try entryConverter.value(text: state.text, kind: state.kind, bits: state.value.bits, signage: state.value.signage)
                else { return .none }
                state.value = value
                return .send(.delegate(.valueUpdated(value)))

            case .binding(\.value): // value --> text
                state.isError = false
                state.text = try entryConverter.text(value: state.value, kind: state.kind)
                let bits = state.value.bits
                state.binText?.bits = bits
                return .none

            case .binding:
                return .none

            case .binText:
                return .none

            case .confirmationKeyPressed:
                state.isError = false
                state.text = try entryConverter.text(value: state.value, kind: state.kind)
                return .none

            case .delegate:
                return .none
            }
        } catch {
            print("unhandled error: \(error)")
            state.isError = true
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
