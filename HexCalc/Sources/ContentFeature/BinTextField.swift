import ComposableArchitecture
import SwiftUI

struct BinTextField: View {
    @Bindable var store: StoreOf<BinTextFieldReducer>

    init(store: StoreOf<BinTextFieldReducer>) {
        self.store = store
    }

    var body: some View {
        HStack(spacing: 3) {
            Spacer()
            ForEach(store.digits, id: \.index) { ic in
                Text("\(ic.value)")
                    .background(store.selectedBits.contains(ic.index)
                        ? Color.accentColor
                        : Color(nsColor: .unemphasizedSelectedTextBackgroundColor)
                    )
                    .onTapGesture {
                        store.send(.bitTapped(index: ic.index))
                    }

                if ic.index.isMultiple(of: 4) && ic.index != store.bitWidth.rawValue {
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
    }
}

public struct BinTextFieldPreviewContainer: View {
    @State var binTextFieldStore = Store(initialState: BinTextFieldReducer.State()) {
        BinTextFieldReducer()
    }

    public var body: some View {
        VStack {
            BitWidthPicker(selectedBitWidth: $binTextFieldStore.bitWidth)

            TextField("", text: $binTextFieldStore.text)
                .entryTextStyle()

            BinTextField(store: binTextFieldStore)
        }
        .padding()
    }
}

#Preview {
    BinTextFieldPreviewContainer()
        .frame(width: 500)
}
