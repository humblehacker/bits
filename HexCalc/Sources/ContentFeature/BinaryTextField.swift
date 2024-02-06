import ComposableArchitecture
import SwiftUI

struct BinaryTextField: View {
    @State var store: StoreOf<BinaryTextFieldReducer>
    @Binding var text: String

    init(text: Binding<String>, store: StoreOf<BinaryTextFieldReducer>) {
        self.store = store
        _text = text
    }

    var body: some View {
        HStack(spacing: 3) {
            let _ = Self._printChanges()

            Spacer()
            ForEach(store.digits, id: \.index) { digit in
                Text(String(digit.value.rawValue))
                    .background(store.selectedBits.contains(digit.index)
                        ? Color.accentColor
                        : Color(nsColor: .unemphasizedSelectedTextBackgroundColor)
                    )
                    .onTapGesture {
                        store.send(.bitTapped(index: digit.index))
                    }

                if digit.index.isMultiple(of: 4) && digit.index != store.bitWidth.rawValue {
                    Text(" ")
                }
            }
        }
        .entryTextStyle()
        .focusable()
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { keyPress in
            let shiftDown = keyPress.modifiers.contains(.shift)
            store.send(.cursorMovementKeyPressed(keyPress.key, extend: shiftDown))
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
    @State var binTextFieldStore = Store(initialState: BinaryTextFieldReducer.State()) {
        BinaryTextFieldReducer()
    }

    public var body: some View {
        VStack {
            BitWidthPicker(selectedBitWidth: $binTextFieldStore.bitWidth)

            TextField("", text: $binTextFieldStore.text)
                .entryTextStyle()

            BinaryTextField(text: .constant(""), store: binTextFieldStore)
        }
        .padding()
    }
}

#Preview {
    BinaryTextFieldPreviewContainer()
        .frame(width: 500)
}
