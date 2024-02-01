import ComposableArchitecture
import SwiftUI

struct IndexedCharacter: Equatable {
    let index: Int
    let character: Character
}

@Reducer
public struct BinTextFieldReducer {
    @ObservableState
    public struct State: Equatable {
        var bitWidth: Bits = ._32
        var selectedBits: Set<Int> = []
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
        case bitOperation(BitOp)
        case bitTapped(index: Int)
        case bitTyped(String)
        case cancelTypeoverKeyPressed
        case cursorMovementKeyPressed(KeyEquivalent)
        case selectAllShortcutPressed
        case toggleBitKeyPressed
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

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .bitTapped(index):
                if state.selectedBits.contains(index) {
                    state.selectedBits.removeAll()
                } else {
                    state.selectedBits = [index]
                }
                return .none

            case let .bitOperation(bitOp):
                guard let currentValue = Int(state.text) else { return .none }

                var newValue = currentValue

                for selectedBit in state.selectedBits {
                    let bitIndex = state.bitWidth.rawValue - selectedBit

                    newValue = switch bitOp {
                    case .set: newValue | (1 << bitIndex)
                    case .unset: newValue & ~(1 << bitIndex)
                    case .toggle: newValue ^ (1 << bitIndex)
                    }
                }

                state.text = String(newValue)
                state.updateBinCharacters()
                return .none

            case let .bitTyped(bit):
                return .send(.bitOperation(bit == "1" ? .set : .unset))

            case .cancelTypeoverKeyPressed:
                state.selectedBits.removeAll()
                return .none

            case let .cursorMovementKeyPressed(key):
                switch key {
                case .leftArrow:
                    let newSelectedBit = state.selectedBits.sorted().first ?? state.bitWidth.rawValue + 1
                    state.selectedBits = [max(1, newSelectedBit - 1)]

                case .rightArrow:
                    let newSelectedBit = state.selectedBits.sorted().last ?? 0
                    state.selectedBits = [min(state.bitWidth.rawValue, newSelectedBit + 1)]

                default:
                    ()
                }
                return .none

            case .selectAllShortcutPressed:
                state.selectedBits = Set(1 ... state.bitWidth.rawValue)
                return .none

            case .toggleBitKeyPressed:
                return .send(.bitOperation(.toggle))
            }
        }
    }

    public enum BitOp {
        case set
        case unset
        case toggle
    }
}
