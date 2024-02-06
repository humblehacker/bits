import ComposableArchitecture
import SwiftUI

@Reducer
public struct BinaryTextFieldReducer {
    @ObservableState
    public struct State: Equatable {
        var bitWidth: Bits
        var selectedBits: Set<Int>
        var currentBit: Int?
        var text: String
        var digits: [BinaryDigitState]

        public init(
            bitWidth: Bits = ._8,
            selectedBits: Set<Int> = [],
            currentBit: Int? = nil,
            text: String = "0",
            digits: [BinaryDigitState] = []
        ) {
            self.bitWidth = bitWidth
            self.selectedBits = selectedBits
            self.currentBit = currentBit
            self.text = text
            self.digits = digits
            updateBinCharacters()
        }

        mutating func updateBinCharacters() {
            digits = (Int(text, radix: 2) ?? 0)
                .paddedBinaryString(bits: bitWidth.rawValue, blockSize: 0)
                .suffix(bitWidth.rawValue)
                .enumerated()
                .map { BinaryDigitState(index: $0.0 + 1, value: $0.1) }
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case bitOperation(BitOp)
        case bitTapped(index: Int)
        case bitTyped(String)
        case cancelTypeoverKeyPressed
        case cursorMovementKeyPressed(KeyEquivalent, extend: Bool)
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
            reduce(state: &state, action: action)
        }
    }

    func reduce(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case let .bitTapped(index):
            if state.selectedBits.contains(index) {
                state.selectedBits.removeAll()
                state.currentBit = nil
            } else {
                state.selectedBits = [index]
                state.currentBit = index
            }
            return .none

        case let .bitOperation(bitOp):
            guard let currentValue = Int(state.text, radix: 2) else { return .none }

            var newValue = currentValue

            for selectedBit in state.selectedBits {
                let bitIndex = state.bitWidth.rawValue - selectedBit

                newValue = switch bitOp {
                case .set: newValue | (1 << bitIndex)
                case .unset: newValue & ~(1 << bitIndex)
                case .toggle: newValue ^ (1 << bitIndex)
                }
            }

            state.text = String(newValue, radix: 2)
            state.updateBinCharacters()
            return .none

        case let .bitTyped(bit):
            return .send(.bitOperation(bit == "1" ? .set : .unset))

        case .cancelTypeoverKeyPressed:
            state.selectedBits.removeAll()
            state.currentBit = nil
            return .none

        case let .cursorMovementKeyPressed(key, extend):
            let newSelectedBit: Int? = switch key {
            case .leftArrow:
                (state.currentBit ?? state.bitWidth.rawValue + 1) - 1

            case .rightArrow:
                (state.currentBit ?? 0) + 1

            default:
                nil
            }

            guard let newSelectedBit = newSelectedBit?.clamped(to: 1 ... state.bitWidth.rawValue) else { return .none }

            if extend {
                if state.selectedBits.contains(newSelectedBit) {
                    if newSelectedBit != state.currentBit {
                        state.selectedBits.remove(state.currentBit ?? newSelectedBit)
                    }
                } else {
                    state.selectedBits.insert(newSelectedBit)
                }
            } else {
                state.selectedBits = [newSelectedBit]
            }

            state.currentBit = newSelectedBit

            return .none

        case .selectAllShortcutPressed:
            state.selectedBits = Set(1 ... state.bitWidth.rawValue)
            state.currentBit = nil
            return .none

        case .toggleBitKeyPressed:
            return .send(.bitOperation(.toggle))
        }
    }

    public enum BitOp {
        case set
        case unset
        case toggle
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
