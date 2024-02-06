import ComposableArchitecture
import SwiftUI

struct BinaryTextField: View {
    @State var store: StoreOf<BinaryTextFieldReducer>
    @Binding var text: String
    @State var textHeight: Double

    init(text: Binding<String>, store: StoreOf<BinaryTextFieldReducer>) {
        self.store = store
        _text = text
        textHeight = 0
    }

    var body: some View {
        HStack(spacing: 0) {
            let _ = Self._printChanges()

            Spacer()
            ForEach(store.digits, id: \.index) { digit in
                HStack {
                    Text(String(digit.value.rawValue))
                        .background(
                            store.selectedBits.contains(digit.index)
                            ? Color(nsColor: .selectedTextBackgroundColor)
                            : Color(nsColor: .unemphasizedSelectedTextBackgroundColor)
                        )
                        .overlay {
                            GeometryReader { geo in
                                Color.clear.task(id: geo.size.height) {
                                    self.textHeight = geo.size.height
                                }
                            }
                        }
                        .onTapGesture {
                            store.send(.bitTapped(index: digit.index))
                        }
                    Spacer()
                        .frame(width: 3, height: textHeight)
                        .background(store.selectedBits.contains(digit.index) && store.selectedBits.sorted().last != digit.index
                                    ? Color(nsColor: .selectedTextBackgroundColor)
                                    : Color(nsColor: .unemphasizedSelectedTextBackgroundColor))

                }

                if digit.index.isMultiple(of: 4) && digit.index != store.bitWidth.rawValue {
                    Text(" ")
                        .background(store.selectedBits.contains(digit.index) && store.selectedBits.sorted().last != digit.index
                                    ? Color(nsColor: .selectedTextBackgroundColor)
                                    : Color(nsColor: .unemphasizedSelectedTextBackgroundColor))
                }
            }
        }
        .focusable()
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { keyPress in
            let shiftKeyDown = keyPress.modifiers.contains(.shift)
            store.send(.cursorMovementKeyPressed(keyPress.key, extend: shiftKeyDown))
            return .handled
        }
        .onKeyPress(keys: ["0", "1"]) { keyPress in
            store.send(.bitTyped(String(keyPress.key.character)))
            return .handled
        }
        .onKeyPress(.space) {
            store.send(.toggleBitKeyPressed)
            return .handled
        }
        .onKeyPress(.escape) {
            store.send(.cancelTypeoverKeyPressed)
            return .handled
        }
        .onKeyPress(keys: ["a"]) { keyPress in
            guard keyPress.modifiers.contains(.command) else { return .ignored }
            store.send(.selectAllShortcutPressed)
            return .handled
        }
        .onChange(of: text) {
            store.send(.binding(.set(\.text, text)))
        }
        .onChange(of: store.text) {
            self.text = store.text
        }
    }
}

public struct BinaryTextFieldPreviewContainer: View {
    @State var binTextFieldStore = Store(
        initialState: BinaryTextFieldReducer.State(
            selectedBits: Set(1 ... 5)
        )
    ) {
        BinaryTextFieldReducer()
    }

    public var body: some View {
        VStack {
            BitWidthPicker(selectedBitWidth: $binTextFieldStore.bitWidth)

            TextField("", text: $binTextFieldStore.text)
                .entryTextStyle()

            BinaryTextField(text: .constant(""), store: binTextFieldStore)
                .entryTextStyle()
        }
        .padding()
    }
}

#Preview {
    BinaryTextFieldPreviewContainer()
        .frame(width: 500)
}
