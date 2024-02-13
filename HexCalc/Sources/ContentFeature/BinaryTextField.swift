import ComposableArchitecture
import SwiftUI
import UI

struct BinaryTextField: View {
    @State var store: StoreOf<BinaryTextFieldReducer>
    @Binding var text: String
    @State var digitFrames: [Int: CGRect] = [:]
    @State var bounds: CGRect = .zero
    let cspace: NamedCoordinateSpace = .named("BinaryTextField")

    init(text: Binding<String>, store: StoreOf<BinaryTextFieldReducer>) {
        self.store = store
        _text = text
    }

    var drag: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: cspace)
            .onChanged { gesture in
                guard let digit = digit(at: gesture.location) else { return }
                store.send(.dragSelectDigit(digit))
            }
            .onEnded { _ in store.send(.endDragSelection) }
    }

    var body: some View {
        HStack(spacing: 0) {
            let _ = Self._printChanges()

            Spacer()
            ForEach(store.digits) { digit in
                Group {
                    Text(String(digit.value.rawValue))
                        .background(
                            store.state.digitSelected(digit)
                                ? Color(nsColor: .selectedTextBackgroundColor)
                                : Color(nsColor: .unemphasizedSelectedTextBackgroundColor)
                        )
                        .border(
                            store.state.showCursorForDigit(digit)
                                ? Color(nsColor: .textInsertionPointColor)
                                : Color.clear,
                            width: 1.5
                        )
                        .overlay {
                            GeometryReader { geo in
                                let frame = geo.frame(in: cspace)
                                Color.clear.task(id: frame) {
                                    self.digitFrames[digit.index] = frame
                                    self.bounds = geo.bounds(of: cspace) ?? .zero
                                }
                            }
                        }

                    Spacer()
                        .frame(
                            width: store.state.spacerWidthForDigit(digit),
                            height: digitFrames[digit.index]?.size.height ?? 44
                        )
                        .background(
                            store.state.digitSpacerSelected(digit)
                                ? Color(nsColor: .selectedTextBackgroundColor)
                                : Color(nsColor: .unemphasizedSelectedTextBackgroundColor)
                        )
                }
                .onTapGesture {
                    let shiftKeyDown = NSEvent.modifierFlags.contains(.shift)
                    store.send(.digitClicked(digit, select: shiftKeyDown))
                }
            }
        }
        .focusable()
        .coordinateSpace(cspace)
        .highPriorityGesture(drag)
        .cursor(.iBeam)
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
        .onChange(of: store.bitWidth) {
            self.digitFrames = [:]
        }
    }

    func digit(at point: CGPoint) -> BinaryDigit? {
        guard let index = digitFrames.filter({ $0.value.contains(point) }).keys.first else { return nil }
        return store.digits[id: index]
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

    public init() {}

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
                Text("selectingDigit: \(String(describing: binTextFieldStore.selectingDigit))")
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
