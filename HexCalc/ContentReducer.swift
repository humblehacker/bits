import ComposableArchitecture
import Dependencies
import Foundation
import Observation

private let defaultBits: Bits = ._32
private let minWidth = 450.0
private let maxWidth = 730.0

enum FocusedField {
    case hex
    case dec
    case bin

}

@Reducer
struct ContentReducer {

    @ObservableState
    struct State {
        var idealWidth: Double = idealWindowWidth(bits: defaultBits)
        var bits: Bits = defaultBits
        var hexText: String = "0"
        var decText: String = "0"
        var binText: String = integerToPaddedBinaryString(0, bits: defaultBits.rawValue)
        var focusedField: FocusedField?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case decTextChanged(String)
        case hexTextChanged(String)
        case binTextChanged(String)
        case selectedBitWidthChanged(Bits)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.bits = loadBits()
                state.focusedField = .dec
                return .none

            case .decTextChanged(let new):
                guard state.focusedField == .dec else { return .none }
                let value = Int(new, radix: 10) ?? 0
                state.hexText = String(value, radix: 16).uppercased()
                state.binText = integerToPaddedBinaryString(value, bits: state.bits.rawValue)
                return .none

            case .hexTextChanged(let new):
                guard state.focusedField == .hex else { return .none }
                let value = Int(new, radix: 16) ?? 0
                state.decText = String(value, radix: 10)
                state.binText = integerToPaddedBinaryString(value, bits: state.bits.rawValue)
                return .none

            case .binTextChanged(let new):
                guard state.focusedField == .bin else { return .none }
                let value = Int(new.filter { !$0.isWhitespace }, radix: 2) ?? 0
                state.hexText = String(value, radix: 16).uppercased()
                state.decText = String(value, radix: 10)
                return .none

            case .selectedBitWidthChanged(let newBits):
                let value = Int(state.decText, radix: 10) ?? 0
                state.hexText = String(value, radix: 16).uppercased()
                state.decText = String(value, radix: 10)
                state.binText = integerToPaddedBinaryString(value, bits: newBits.rawValue)
                state.bits = newBits
                saveBits(state.bits)
                state.idealWidth = idealWindowWidth(bits: state.bits)
                return .none
            }
        }
        ._printChanges()
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
