import BigInt
import ComposableArchitecture
import SwiftUI
import Utils

public let maxBits = Bits._64

@Reducer
public struct BinaryTextFieldReducer {
    @ObservableState
    public struct State: Equatable {
        var bitWidth: Bits
        var digits: IdentifiedArrayOf<BinaryDigit>
        var isFocused: Bool
        var selection: Selection
        var selectingDigit: BinaryDigit?
        var text: String

        public init(
            bitWidth: Bits = ._8,
            selection: Selection = .init(bounds: Bits._8.selectionBounds()),
            text: String = "0",
            digits: IdentifiedArrayOf<BinaryDigit> = [],
            isFocused: Bool = false
        ) {
            self.bitWidth = bitWidth
            self.selection = selection
            self.text = text
            self.digits = digits
            self.isFocused = isFocused
            selectingDigit = nil
            updateDigits()
        }

        mutating func updateDigits() {
            // This is just the rendering step, where we take a binary string of arbitrary
            // width and render it as a 64bit binary string. Any necessary bit manipulations
            // should have already been applied. For example, negative values should have
            // already been converted to their twos-complement.
            let value = BigUInt(text, radix: 2)!

            let newDigits = value
                .fixedWidthBinaryString(64)
                .enumerated()
                .map { BinaryDigit(index: $0.0, value: $0.1) }

            digits = IdentifiedArray(uniqueElements: newDigits)
        }

        func showCursorForDigit(_ digit: BinaryDigit) -> Bool {
            selection.cursorIndex == digit.index // && !digitSelected(digit)
        }

        func digitSelected(_ digit: BinaryDigit) -> Bool {
            selection.selectedIndexes?.contains(digit.index) ?? false
        }

        func digitDisabled(_ digit: BinaryDigit) -> Bool {
            let bitIndex = maxBits.rawValue - 1 - digit.index
            return bitIndex >= bitWidth.rawValue
        }

        func spacingForDigit(_ digit: BinaryDigit) -> Double {
            guard !digitIsLast(digit) else { return 0.0 }

            let displayIndex = digit.index + 1
            return displayIndex.isMultiple(of: 4) ? 8.0 : 1.0
        }

        func digitSpacingSelected(_ digit: BinaryDigit) -> Bool {
            digitSelected(digit) && !digitIsLastSelected(digit)
        }

        func digitIsLast(_ digit: BinaryDigit) -> Bool {
            let displayIndex = digit.index + 1
            return displayIndex.isMultiple(of: 32)
        }

        func digitIsLastSelected(_ digit: BinaryDigit) -> Bool {
            selection.selectedIndexes?.last == digit.index
        }

        mutating
        func applyBitOperation(bitOp: BitOp) -> EffectOf<BinaryTextFieldReducer> {
            guard let currentValue = Int(text, radix: 2) else { return .none }

            var newValue = currentValue

            let bits = selection.selectedIndexes ?? selection.cursorIndex ..<+ 1
            for bit in bits {
                let bitIndex = 64 - bit - 1

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
                    state.selection.setBounds(state.bitWidth.selectionBounds())
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

public extension Bits {
    func selectionBounds(within bits: Bits = maxBits) -> Range<Int> {
        return bits.rawValue - rawValue ..< bits.rawValue
    }
}
