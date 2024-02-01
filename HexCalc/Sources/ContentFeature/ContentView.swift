import ComposableArchitecture
import HistoryFeature
import SwiftUI

public struct ContentView: View {
    @Bindable var store: StoreOf<ContentReducer>
    @FocusState var focusedField: FocusedField?

    public init(store: StoreOf<ContentReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            Entry(store: store.scope(state: \.expEntry, action: \.expEntry))
                .onKeyPress(.upArrow) {
                    store.send(.upArrowPressed)
                    return .handled
                }
                .popover(item: $store.scope(state: \.destination?.history, action: \.destination.history)) { store in
                    HistoryPicker(store: store)
                        .frame(width: self.store.expEntry.width)
                }
                .focused($focusedField, equals: .exp)

            Entry(store: store.scope(state: \.decEntry, action: \.decEntry))
                .focused($focusedField, equals: .dec)

            Entry(store: store.scope(state: \.hexEntry, action: \.hexEntry))
                .focused($focusedField, equals: .hex)

            Entry(store: store.scope(state: \.binEntry, action: \.binEntry))
                .focused($focusedField, equals: .bin)
        }
        .padding()
        .toolbar {
            BitWidthPicker(selectedBitWidth: $store.selectedBitWidth)
        }
        .frame(minWidth: 450, idealWidth: store.idealWidth, maxWidth: 730)
        .onAppear { store.send(.onAppear) }
        .onChange(of: store.idealWidth, initial: true) { _, new in
            let window = NSApplication.shared.windows.first!
            let height = window.frame.height
            window.setContentSize(NSSize(width: new, height: height))
        }
        .bind($store.focusedField, to: $focusedField)
    }
}

#Preview {
    ContentView(store: Store(initialState: ContentReducer.State()) {
        ContentReducer()
    })
}
