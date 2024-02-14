import ComposableArchitecture
import SwiftUI

@Reducer
public struct BinaryTextFieldReducer {
    @ObservableState
    public struct State: Equatable {
        var bitWidth: Bits
        var selection: Selection
        var text: String
        var digits: IdentifiedArrayOf<BinaryDigit>
        var selectingDigit: BinaryDigit?

        public init(
            bitWidth: Bits = ._8,
            selection: Selection = .init(bitWidth: Bits._8),
            text: String = "0",
            digits: IdentifiedArrayOf<BinaryDigit> = []
        ) {
            self.bitWidth = bitWidth
            self.selection = selection
            self.text = text
            self.digits = digits
            selectingDigit = nil
            updateDigits()
        }

        mutating func updateDigits() {
            digits = IdentifiedArray(uniqueElements: (Int(text, radix: 2) ?? 0)
                .paddedBinaryString(bits: bitWidth.rawValue, blockSize: 0)
                .suffix(bitWidth.rawValue)
                .enumerated()
                .map { BinaryDigit(index: $0.0, value: $0.1) }
            )
        }

        func showCursorForDigit(_ digit: BinaryDigit) -> Bool {
            selection.cursorIndex == digit.index // && !digitSelected(digit)
        }

        func digitSelected(_ digit: BinaryDigit) -> Bool {
            selection.selectedIndexes?.contains(digit.index) ?? false
        }

        func spacerWidthForDigit(_ digit: BinaryDigit) -> Double {
            guard !digitIsLast(digit) else { return 0.0 }

            let displayIndex = digit.index + 1
            return displayIndex.isMultiple(of: 4) ? 10.0 : 3.0
        }

        func digitSpacerSelected(_ digit: BinaryDigit) -> Bool {
            digitSelected(digit) && !digitIsLastSelected(digit)
        }

        func digitIsLast(_ digit: BinaryDigit) -> Bool {
            digit.index == bitWidth.rawValue - 1
        }

        func digitIsLastSelected(_ digit: BinaryDigit) -> Bool {
            selection.selectedIndexes?.last == digit.index
        }

        mutating
        func applyBitOperation(bitOp: BitOp) -> EffectOf<BinaryTextFieldReducer> {
            guard
                let currentValue = Int(text, radix: 2),
                let selectedBits = selection.selectedIndexes
            else { return .none }

            var newValue = currentValue

            for selectedBit in selectedBits {
                let bitIndex = bitWidth.rawValue - selectedBit

                newValue = switch bitOp {
                case .set: newValue | (1 << bitIndex)
                case .unset: newValue & ~(1 << bitIndex)
                case .toggle: newValue ^ (1 << bitIndex)
                }
            }

            text = String(newValue, radix: 2)
            updateDigits()
            return .none
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case digitClicked(BinaryDigit, select: Bool)
        case bitTyped(String)
        case cancelTypeoverKeyPressed
        case cursorMovementKeyPressed(CursorDirection, extend: Bool)
        case selectAllShortcutPressed
        case dragSelectDigit(_ digit: BinaryDigit)
        case endDragSelection
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
        ._printChanges()
    }

    func reduce(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case let .digitClicked(digit, select):
            if select {
                state.selection.clickSelect(digit.index)
            } else {
                state.selection.setCursor(digit.index)
            }
            return .none

        case let .bitTyped(bit):
            return state.applyBitOperation(bitOp: bit == "1" ? .set : .unset)

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

        case let .dragSelectDigit(digit):
            if state.selectingDigit == nil {
                state.selection.clear()
            }
            state.selectingDigit = digit
            state.selection.dragSelect(digit.index)
            return .none

        case .endDragSelection:
            state.selectingDigit = nil
            return .none

        case .toggleBitKeyPressed:
            return state.applyBitOperation(bitOp: .toggle)
        }
    }

    public enum BitOp {
        case set
        case unset
        case toggle
    }
}
