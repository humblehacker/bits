import ComposableArchitecture
import SwiftUI

public struct ContentView: View {
    @State var store: StoreOf<ContentReducer>
    @FocusState var focusedField: FocusedField?

    public init(store: StoreOf<ContentReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            Entry(store: store.scope(state: \.expEntry, action: \.expEntry))
            Entry(store: store.scope(state: \.decEntry, action: \.decEntry))
            Entry(store: store.scope(state: \.hexEntry, action: \.hexEntry))
            Entry(store: store.scope(state: \.binEntry, action: \.binEntry))
        }
        .padding()
        .toolbar {
            Picker("", selection: $store.selectedBitWidth) {
                Text("8").tag(Bits._8)
                Text("16").tag(Bits._16)
                Text("32").tag(Bits._32)
                Text("64").tag(Bits._64)
            }
            .pickerStyle(.segmented)
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
