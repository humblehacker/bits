import ComposableArchitecture

struct IndexedCharacter: Equatable {
    let index: Int
    let character: Character
}

@Reducer
public struct BinTextFieldReducer {
    @ObservableState
    public struct State: Equatable {
        var bitWidth: Bits = ._32
        var text: String = "0"
        var binCharacters: [IndexedCharacter] = [IndexedCharacter(index: 0, character: "0")]

        init() {
            updateBinCharacters()
        }

        mutating func updateBinCharacters() {
            let value = Int(text) ?? 0
            let binString = value.paddedBinaryString(bits: bitWidth.rawValue, blockSize: 0)
            binCharacters = binString.enumerated().map { IndexedCharacter(index: $0.0 + 1, character: $0.1) }
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
            .onChange(of: \.text) { _, _ in
                Reduce { state, _ in
                    state.updateBinCharacters()
                    return .none
                }
            }
            .onChange(of: \.bitWidth) { _, _ in
                Reduce { state, _ in
                    state.updateBinCharacters()
                    return .none
                }
            }

        Reduce { _, action in
            switch action {
            case .binding:
                return .none
            }
        }
    }
}
