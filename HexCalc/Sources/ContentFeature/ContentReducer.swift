import ComposableArchitecture
import Dependencies
import ExpressionEvaluator
import Foundation
import Observation

private let defaultBits: Bits = ._32
private let minWidth = 450.0
private let maxWidth = 730.0

public enum FocusedField {
    case exp
    case bin
    case dec
    case hex
}

@Reducer
public struct ContentReducer {
    @ObservableState
    public struct State {
        var idealWidth: Double
        var selectedBitWidth: Bits
        var expEntry: EntryReducer.State
        var hexEntry: EntryReducer.State
        var decEntry: EntryReducer.State
        var binEntry: EntryReducer.State
        var focusedField: FocusedField?

        public init(
            idealWidth: Double = 100.0,
            selectedBitWidth: Bits = ._8,
            expEntry: EntryReducer.State = EntryReducer.State(kind: .exp),
            hexEntry: EntryReducer.State = EntryReducer.State(kind: .hex),
            decEntry: EntryReducer.State = EntryReducer.State(kind: .dec),
            binEntry: EntryReducer.State = EntryReducer.State(kind: .bin),
            focusedField: FocusedField? = nil
        ) {
            self.idealWidth = idealWidth
            self.selectedBitWidth = selectedBitWidth
            self.expEntry = expEntry
            self.hexEntry = hexEntry
            self.decEntry = decEntry
            self.binEntry = binEntry
            self.focusedField = focusedField
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case expEntry(EntryReducer.Action)
        case decEntry(EntryReducer.Action)
        case hexEntry(EntryReducer.Action)
        case binEntry(EntryReducer.Action)
        case onAppear
    }

    @Dependency(\.expressionEvaluator.evaluate) var evaluateExpression

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.expEntry, action: \.expEntry) { EntryReducer() }
        Scope(state: \.hexEntry, action: \.hexEntry) { EntryReducer() }
        Scope(state: \.decEntry, action: \.decEntry) { EntryReducer() }
        Scope(state: \.binEntry, action: \.binEntry) { EntryReducer() }

        Reduce { state, action in
            switch action {
            case .onAppear:
                state.selectedBitWidth = loadBits()
                state.idealWidth = idealWindowWidth(bits: state.selectedBitWidth)
                state.focusedField = .exp
                state.expEntry.text = ""
                update(&state, from: 0)
                return .none

            case .expEntry(.binding(\.text)):
                let value: Int
                do {
                    value = try evaluateExpression(state.expEntry.text)
                } catch {
                    print(error)
                    return .none
                }
                update(&state, from: value)
                return .none

            case .expEntry(.binding(\.focusedField)):
                state.focusedField = state.expEntry.focusedField
                return .none

            case .expEntry:
                return .none

            case .decEntry(.binding(\.text)):
                guard state.focusedField == .dec else { return .none }
                let value = Int(state.decEntry.text, radix: 10) ?? 0
                update(&state, from: value)
                return .none

            case .decEntry(.binding(\.focusedField)):
                state.focusedField = state.decEntry.focusedField
                return .none

            case .decEntry:
                return .none

            case .hexEntry(.binding(\.text)):
                guard state.focusedField == .hex else { return .none }
                let value = Int(state.hexEntry.text, radix: 16) ?? 0
                update(&state, from: value)
                return .none

            case .hexEntry(.binding(\.focusedField)):
                state.focusedField = state.hexEntry.focusedField
                return .none

            case .hexEntry:
                return .none

            case .binEntry(.binding(\.text)):
                guard state.focusedField == .bin else { return .none }
                let value = Int(state.binEntry.text.filter { !$0.isWhitespace }, radix: 2) ?? 0
                update(&state, from: value)
                return .none

            case .binEntry(.binding(\.focusedField)):
                state.focusedField = state.binEntry.focusedField
                return .none

            case .binEntry:
                return .none

            case .binding(\.selectedBitWidth):
                let value = Int(state.decEntry.text, radix: 10) ?? 0
                update(&state, from: value)
                saveBits(state.selectedBitWidth)
                state.idealWidth = idealWindowWidth(bits: state.selectedBitWidth)
                return .none

            case .binding:
                return .none
            }
        }
        ._printChanges()
    }

    func update(_ state: inout ContentReducer.State, from value: Int) {
        state.hexEntry.text = String(value, radix: 16).uppercased()
        state.decEntry.text = String(value, radix: 10)
        state.binEntry.text = integerToPaddedBinaryString(value, bits: state.selectedBitWidth.rawValue)
    }

    func saveBits(_ bits: Bits) {
        UserDefaults.standard.setValue(bits.rawValue, forKey: "bits")
    }

    func loadBits() -> Bits {
        let bits = UserDefaults.standard.integer(forKey: "bits")
        return Bits(rawValue: bits) ?? defaultBits
    }
}

public enum Bits: Int {
    case _8 = 8
    case _16 = 16
    case _32 = 32
    case _64 = 64
}

func idealWindowWidth(bits: Bits) -> Double {
    return switch bits {
    case ._8, ._16, ._32: minWidth
    case ._64: maxWidth
    }
}

func integerToPaddedBinaryString(_ value: Int, bits: Int) -> String {
    let binaryString = String(value, radix: 2)
    let paddedString = String(repeating: "0", count: max(0, bits - binaryString.count)) + binaryString
    let blockSize = 4
    var result = ""
    for (index, char) in paddedString.enumerated() {
        if index % blockSize == 0 && index != 0 {
            result += " "
        }
        result += String(char)
    }
    return result
}
