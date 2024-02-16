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
        VStack(spacing: 10) {
            BinaryTextFieldRow(.first, store: store, digitFrames: $digitFrames)
            BinaryTextFieldRow(.last, store: store, digitFrames: $digitFrames)
        }
        .focusable()
        .padding()
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
    }

    func digit(at point: CGPoint) -> BinaryDigit? {
        guard let index = digitFrames.filter({ $0.value.contains(point) }).keys.first else { return nil }
        return store.digits[id: index]
    }
}

struct BinaryTextFieldRow: View {
    @Bindable var store: StoreOf<BinaryTextFieldReducer>
    @Binding var digitFrames: [Int: CGRect]
    @State var textHeight: Double = 0.0
    let cspace: NamedCoordinateSpace = .named("BinaryTextField")

    enum RowID { case first; case last }
    let rowID: RowID

    init(_ rowID: RowID, store: StoreOf<BinaryTextFieldReducer>, digitFrames: Binding<[Int: CGRect]>) {
        self.rowID = rowID
        self.store = store
        _digitFrames = digitFrames
        textHeight = textHeight
    }

    var digits: Slice<IdentifiedArrayOf<BinaryDigit>> {
        switch rowID {
        case .first: store.digits.prefix(32)
        case .last: store.digits.suffix(32)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(digits) { digit in
                VStack {
                    Text(String(digit.value.rawValue))
                        .fixedSize()
                        .padding(1)
                        .foregroundColor(foregroundColor(digit: digit))
                        .layoutPriority(1)
                        // text cursor
                        .border(cursorColor(digit: digit), width: 1.5)
                        // selection
                        .background(selectionBackgroundColor(digit: digit))
                        // inter-digit variable spacing
                        .padding(.trailing, store.state.spacingForDigit(digit))
                        // selection of above spacing
                        .background(spacingSelectionBackgroundColor(digit: digit))
                        .overlay {
                            GeometryReader { geo in
                                let frame = geo.frame(in: cspace)
                                Color.clear
                                    .task(id: frame) { self.digitFrames[digit.index] = frame }
                                    .task(id: frame.size.height) { self.textHeight = frame.size.height }
                            }
                        }
                        .overlay(alignment: .bottomLeading) {
                            Group {
                                let indexesToShow = [63, 47, 32, 31, 15, 0]
                                let bitIndex = maxBits.rawValue - digit.index - 1
                                if indexesToShow.contains(bitIndex) {
                                    Text("\(bitIndex)")
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("\(bitIndex)")
                                        .font(.caption)
                                        .hidden()
                                }
                            }
                            .alignmentGuide(.leading) { $0[.leading] }
                            .fixedSize()
                            .offset(x: 1, y: textHeight)
                        }
                        .onTapGesture {
                            let shiftKeyDown = NSEvent.modifierFlags.contains(.shift)
                            store.send(.digitClicked(digit, select: shiftKeyDown))
                        }

                    Spacer()
                        .frame(height: textHeight)
                }
            }
        }
    }

    func foregroundColor(digit: BinaryDigit) -> Color {
        store.state.digitDisabled(digit)
            ? Color(nsColor: .disabledControlTextColor)
            : Color(nsColor: .textColor)
    }

    func cursorColor(digit: BinaryDigit) -> Color {
        store.state.showCursorForDigit(digit)
            ? cursorColor()
            : Color.clear
    }

    func cursorColor() -> Color {
        store.isFocused
            ? Color(nsColor: .textInsertionPointColor)
            : Color(nsColor: .disabledControlTextColor)
    }

    func selectionBackgroundColor(digit: BinaryDigit) -> Color {
        store.state.digitSelected(digit)
            ? Color(nsColor: .selectedTextBackgroundColor)
            : Color(nsColor: .unemphasizedSelectedTextBackgroundColor)
    }

    func spacingSelectionBackgroundColor(digit: BinaryDigit) -> Color {
        store.state.digitSpacingSelected(digit)
            ? Color(nsColor: .selectedTextBackgroundColor)
            : Color(nsColor: .unemphasizedSelectedTextBackgroundColor)
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

            TextField(text: $binTextFieldStore.text, label: { EmptyView() })
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
        .fixedSize()
}
