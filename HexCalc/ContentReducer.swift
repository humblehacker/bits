import ComposableArchitecture
import Dependencies
import Foundation
import Observation

private let defaultBits: Bits = ._32
private let minWidth = 450.0
private let maxWidth = 730.0

enum FocusedField {
    case exp
    case bin
    case dec
    case hex
}

@Reducer
struct ContentReducer {

    @ObservableState
    struct State {
        var idealWidth: Double = minWidth
        var selectedBitWidth: Bits = ._8
        var expText: String = ""
        var hexText: String = ""
        var decText: String = ""
        var binText: String = ""
        var focusedField: FocusedField?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
    }

    @Dependency(\.expressionEvaluator.evaluate) var evaluateExpression

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.selectedBitWidth = loadBits()
                state.idealWidth = idealWindowWidth(bits: state.selectedBitWidth)
                state.focusedField = .exp
                state.expText = ""
                update(&state, from: 0)
                return .none

            case .binding(\.expText):
                let value: Int
                do {
                    value = try evaluateExpression(state.expText)
                } catch {
                    print(error)
                    return .none
                }
                update(&state, from: value)
                return .none

            case .binding(\.decText):
                guard state.focusedField == .dec else { return .none }
                let value = Int(state.decText, radix: 10) ?? 0
                update(&state, from: value)
                return .none

            case .binding(\.hexText):
                guard state.focusedField == .hex else { return .none }
                let value = Int(state.hexText, radix: 16) ?? 0
                update(&state, from: value)
                return .none

            case .binding(\.binText):
                guard state.focusedField == .bin else { return .none }
                let value = Int(state.binText.filter { !$0.isWhitespace }, radix: 2) ?? 0
                update(&state, from: value)
                return .none

            case .binding(\.selectedBitWidth):
                let value = Int(state.decText, radix: 10) ?? 0
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

    func update(_ state: inout State, from value: Int) {
        state.hexText = String(value, radix: 16).uppercased()
        state.decText = String(value, radix: 10)
        state.binText = integerToPaddedBinaryString(value, bits: state.selectedBitWidth.rawValue)
    }

    func saveBits(_ bits: Bits) {
        UserDefaults.standard.setValue(bits.rawValue, forKey: "bits")
    }

    func loadBits() -> Bits {
        let bits = UserDefaults.standard.integer(forKey: "bits")
        return Bits(rawValue: bits) ?? defaultBits
    }
}

enum Bits: Int {
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
