import ComposableArchitecture
import SwiftUI
import UI
import Utils

struct BinaryTextField: View {
    @Bindable var store: StoreOf<BinaryTextFieldReducer>
    @Binding var text: String
    @State var digitFrames: [Int: CGRect] = [:]
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
        VStack(spacing: 8) {
            PartialBinaryTextField(digits: store.digits.prefix(32))
            PartialBinaryTextField(digits: store.digits.suffix(32))
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

    @ViewBuilder
    func PartialBinaryTextField(digits: Slice<IdentifiedArray<Int, BinaryDigit>>) -> some View {
        HStack(spacing: 0) {
            ForEach(digits) { digit in
                Group {
                    Text(String(digit.value.rawValue))
                        .foregroundColor(
                            store.state.digitDisabled(digit)
                            ? Color(nsColor: .disabledControlTextColor)
                            : Color(nsColor: .textColor)
                        )
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
                                }
                            }
                        }
                    
                    Spacer()
                        .frame(
                            width: store.state.spacerWidthForDigit(digit),
                            height: digitFrames[digit.index]?.size.height ?? 16
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

    @State var binTextFieldStore = {
        let bitWidth = Bits._16
        let bounds = bitWidth.selectionBounds()
        return Store(
            initialState: BinaryTextFieldReducer.State(
                bitWidth: bitWidth,
                selection: Selection(bounds: bounds, selectedIndexes: bounds.lowerBound ..<+ 4)
            )
        ) {
            BinaryTextFieldReducer()
        }
    }()

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
                Text("selection: \(String(describing: binTextFieldStore.selection.selectedIndexes ?? 0 ..< 0))")
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
