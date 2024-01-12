import SwiftUI

enum FocusedField {
    case hex
    case dec
    case bin

}

private let minWidth = 450.0
private let maxWidth = 730.0
private let defaultBits: Bits = ._32

enum Bits: Int {
    case _8 = 8
    case _16 = 16
    case _32 = 32
    case _64 = 64

    var idealWidth: Double {
        switch self {
        case ._8, ._16, ._32: minWidth
        case ._64: maxWidth
        }
    }
}

struct ContentView: View {
    @AppStorage("bits") var storedBits: Bits = defaultBits
    @State var idealWidth: Double = defaultBits.idealWidth
    @State var bits: Bits = defaultBits
    @State var hexText: String = "0"
    @State var decText: String = "0"
    @State var binText: String = integerToPaddedBinaryString(0, bits: defaultBits.rawValue)
    @FocusState var focusedField: FocusedField?

    var body: some View {
        VStack(alignment: .leading) {
            Entry("DEC", entryType: .dec, text: $decText, focusedField: _focusedField)
            Entry("HEX", entryType: .hex, text: $hexText, focusedField: _focusedField)
            Entry("BIN", entryType: .bin, text: $binText, focusedField: _focusedField)
        }
        .padding()
        .toolbar{
            Picker("", selection: $bits) {
                Text("8").tag(Bits._8)
                Text("16").tag(Bits._16)
                Text("32").tag(Bits._32)
                Text("64").tag(Bits._64)
            }
            .pickerStyle(.segmented)
        }
        .frame(minWidth: 450, idealWidth: idealWidth, maxWidth: 730)
        .onAppear {
            bits = storedBits
            focusedField = .dec
        }
        .onChange(of: bits, initial: true) { old, new in
            let value = Int(decText, radix: 10) ?? 0
            hexText = String(value, radix: 16).uppercased()
            decText = String(value, radix: 10)
            binText = integerToPaddedBinaryString(value, bits: bits.rawValue)
            storedBits = bits
            idealWidth = bits.idealWidth
            let window = NSApplication.shared.windows.first!
            let height = window.frame.height
            window.setContentSize(NSSize(width: idealWidth, height: height))
        }
        .onChange(of: hexText, initial: true) { old, new in
            guard focusedField == .hex else { return }
            let value = Int(new, radix: 16) ?? 0
            decText = String(value, radix: 10)
            binText = integerToPaddedBinaryString(value, bits: bits.rawValue)
        }
        .onChange(of: decText, initial: true) { old, new in
            guard focusedField == .dec else { return }
            let value = Int(new, radix: 10) ?? 0
            hexText = String(value, radix: 16).uppercased()
            binText = integerToPaddedBinaryString(value, bits: bits.rawValue)
        }
        .onChange(of: binText, initial: true) { old, new in
            guard focusedField == .bin else { return }
            let value = Int(new.filter { !$0.isWhitespace }, radix: 2) ?? 0
            hexText = String(value, radix: 16).uppercased()
            decText = String(value, radix: 10)
        }
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

#Preview {
    ContentView()
}
