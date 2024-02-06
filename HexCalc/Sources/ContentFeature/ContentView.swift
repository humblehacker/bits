import ComposableArchitecture
import HistoryFeature
import SwiftUI

public struct ContentView: View {
    @State var store: StoreOf<ContentReducer>
    @FocusState var focusedField: EntryKind?

    public init(store: StoreOf<ContentReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            ForEach(store.scope(state: \.entries, action: \.entries)) { store in
                if store.kind == .bin {
                    BinaryTextEntry(store: store)
                        .focused($focusedField, equals: store.kind)
                } else {
                    Entry(store: store)
                        .focused($focusedField, equals: store.kind)
                }
            }
            .onKeyPress(.upArrow) {
                store.send(.upArrowPressed)
                return .handled
            }
            .overlay {
                GeometryReader { geo in
                    Color.clear.onAppear { store.entryWidth = geo.size.width }
                }
            }
        }
        .padding()
        .toolbar {
            BitWidthPicker(selectedBitWidth: $store.selectedBitWidth)
        }
        .frame(minWidth: minWidth, idealWidth: store.idealWidth, maxWidth: maxWidth)
        .onAppear { store.send(.onAppear) }
        .onChange(of: store.idealWidth, initial: true) { _, new in
            let window = NSApplication.shared.windows.first!
            let height = window.frame.height
            window.setContentSize(NSSize(width: new, height: height))
        }
        .popover(item: $store.scope(state: \.destination?.history, action: \.destination.history)) { store in
            HistoryPicker(store: store)
                .frame(width: self.store.entryWidth)
        }
        .bind($store.focusedField, to: $focusedField)
    }
}

#Preview {
    ContentView(store: Store(initialState: ContentReducer.State()) {
        ContentReducer()
    })
}
