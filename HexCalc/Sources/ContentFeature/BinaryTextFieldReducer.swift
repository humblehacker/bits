import ComposableArchitecture
import SwiftUI

@Reducer
public struct BinaryTextFieldReducer {
    @ObservableState
    public struct State: Equatable {
        var bitWidth: Bits
        var selection: Selection
        var text: String
        var digits: [BinaryDigitState]

        public init(
            bitWidth: Bits = ._8,
            selection: Selection = .init(bitWidth: Bits._8),
            text: String = "0",
            digits: [BinaryDigitState] = []
        ) {
            self.bitWidth = bitWidth
            self.selection = selection
            self.text = text
            self.digits = digits
            updateDigits()
        }

        mutating func updateDigits() {
            digits = (Int(text, radix: 2) ?? 0)
                .paddedBinaryString(bits: bitWidth.rawValue, blockSize: 0)
                .suffix(bitWidth.rawValue)
                .enumerated()
                .map { BinaryDigitState(index: $0.0, value: $0.1) }
        }

        func showCursorForDigit(_ digit: BinaryDigitState) -> Bool {
            selection.cursorIndex == digit.index && !digitSelected(digit)
        }

        func digitSelected(_ digit: BinaryDigitState) -> Bool {
            selection.selectedIndexes?.contains(digit.index) ?? false
        }

        func spacerWidthForDigit(_ digit: BinaryDigitState) -> Double {
            guard !digitIsLast(digit) else { return 0.0 }

            let displayIndex = digit.index + 1
            return displayIndex.isMultiple(of: 4) ? 10.0 : 3.0
        }

        func digitSpacerSelected(_ digit: BinaryDigitState) -> Bool {
            digitSelected(digit) && !digitIsLastSelected(digit)
        }

        func digitIsLast(_ digit: BinaryDigitState) -> Bool {
            digit.index == bitWidth.rawValue - 1
        }

        func digitIsLastSelected(_ digit: BinaryDigitState) -> Bool {
            selection.selectedIndexes?.last == digit.index
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case bitOperation(BitOp)
        case bitTapped(index: Int)
        case bitTyped(String)
        case cancelTypeoverKeyPressed
        case cursorMovementKeyPressed(CursorDirection, extend: Bool)
        case selectAllShortcutPressed
        case toggleBitKeyPressed
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
            .onChange(of: \.text) { _, _ in
                Reduce { state, _ in
                    state.updateDigits()
                    return .none
                }
            }
            .onChange(of: \.bitWidth) { _, _ in
                Reduce { state, _ in
                    state.updateDigits()
                    state.selection.setBitWidth(state.bitWidth)
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
            state.selection.setCursor(index)
            return .none

        case let .bitOperation(bitOp):
            guard
                let currentValue = Int(state.text, radix: 2),
                let selectedBits = state.selection.selectedIndexes
            else { return .none }

            var newValue = currentValue

            for selectedBit in selectedBits {
                let bitIndex = state.bitWidth.rawValue - selectedBit

                newValue = switch bitOp {
                case .set: newValue | (1 << bitIndex)
                case .unset: newValue & ~(1 << bitIndex)
                case .toggle: newValue ^ (1 << bitIndex)
                }
            }

            state.text = String(newValue, radix: 2)
            state.updateDigits()
            return .none

        case let .bitTyped(bit):
            return .send(.bitOperation(bit == "1" ? .set : .unset))

        case .cancelTypeoverKeyPressed:
            state.selection.clear()
            return .none

        case let .cursorMovementKeyPressed(direction, extend):
            if extend {
                state.selection.select(towards: direction)
            } else {
                state.selection.moveCursor(direction)
            }
            return .none

        case .selectAllShortcutPressed:
            state.selection.selectAll()
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
