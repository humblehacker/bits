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
        var selectedBit: Int? = nil
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
                state.selectedBit = index
                return .none

            case let .bitOperation(bitOp):
                guard
                    let selectedBit = state.selectedBit,
                    let currentValue = Int(state.text)
                else { return .none }

                let bitIndex = state.bitWidth.rawValue - selectedBit

                let newValue: Int = switch bitOp {
                case .set: currentValue | (1 << bitIndex)
                case .unset: currentValue & ~(1 << bitIndex)
                case .toggle: currentValue ^ (1 << bitIndex)
                }

                state.text = String(newValue)
                state.updateBinCharacters()
                return .none

            case let .bitTyped(bit):
                return .send(.bitOperation(bit == "1" ? .set : .unset))

            case .cancelTypeoverKeyPressed:
                state.selectedBit = nil
                return .none

            case let .cursorMovementKeyPressed(key):
                switch key {
                case .leftArrow:
                    let newSelectedBit = state.selectedBit ?? state.bitWidth.rawValue + 1
                    state.selectedBit = max(1, newSelectedBit - 1)

                case .rightArrow:
                    let newSelectedBit = state.selectedBit ?? 0
                    state.selectedBit = min(state.bitWidth.rawValue, newSelectedBit + 1)

                default:
                    ()
                }
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
