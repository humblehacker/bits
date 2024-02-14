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
                Text(String(digit.value.rawValue))
                    .background(
                        store.state.digitSelected(digit)
                            ? Color(nsColor: .selectedTextBackgroundColor)
                            : Color(nsColor: .unemphasizedSelectedTextBackgroundColor)
                    )
                    .border(
                        store.state.showCursorForDigit(digit)
                            ? Color(nsColor: .textInsertionPointColor)
                            : Color.clear
                    )
                    .overlay {
                        GeometryReader { geo in
                            Color.clear.task(id: geo.size.height) {
                                self.textHeight = geo.size.height
                            }
                        }
                    }
                    .onTapGesture {
                        store.send(.digitClicked(digit))
                    }

                Spacer()
                    .frame(width: store.state.spacerWidthForDigit(digit), height: textHeight)
                    .background(
                        store.state.digitSpacerSelected(digit)
                            ? Color(nsColor: .selectedTextBackgroundColor)
                            : Color(nsColor: .unemphasizedSelectedTextBackgroundColor)
                    )
            }
        }
        .focusable()
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { keyPress in
            let shiftKeyDown = keyPress.modifiers.contains(.shift)
            let direction = CursorDirection.direction(from: keyPress.key)
            store.send(.cursorMovementKeyPressed(direction, extend: shiftKeyDown))
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

extension CursorDirection {
    static func direction(from keyEquivalent: KeyEquivalent) -> CursorDirection {
        switch keyEquivalent {
        case .leftArrow: .left
        case .rightArrow: .right
        default: fatalError()
        }
    }
}

public struct BinaryTextFieldPreviewContainer: View {
    @FocusState var focused: Int?

    @State var binTextFieldStore = Store(
        initialState: BinaryTextFieldReducer.State(
            bitWidth: ._16,
            selection: Selection(bitWidth: Bits._16, selectedIndexes: 0 ..< 4)
        )
    ) {
        BinaryTextFieldReducer()
    }

    public var body: some View {
        VStack {
            BitWidthPicker(selectedBitWidth: $binTextFieldStore.bitWidth)
                .focused($focused, equals: 0)

            TextField("", text: $binTextFieldStore.text)
                .entryTextStyle()
                .focused($focused, equals: 1)

            BinaryTextField(text: .constant(""), store: binTextFieldStore)
                .entryTextStyle()
                .focused($focused, equals: 2)

            HStack {
                Text("cursorIndex: \(binTextFieldStore.selection.cursorIndex)")
                Text("selection: \(binTextFieldStore.selection.selectedIndexes ?? 0 ..< 0)")
                Spacer()
            }
        }
        .padding()
        .onAppear { focused = 2 }
    }
}

#Preview {
    BinaryTextFieldPreviewContainer()
        .frame(width: 500)
}
