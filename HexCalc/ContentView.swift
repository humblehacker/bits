import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    @State var store: StoreOf<ContentReducer>
    @FocusState var focusedField: FocusedField?

    var body: some View {
        VStack(alignment: .leading) {
            Entry("DEC", entryType: .dec, text: $store.decText.sending(\.decTextChanged), focusedField: _focusedField)
            Entry("HEX", entryType: .hex, text: $store.hexText.sending(\.hexTextChanged), focusedField: _focusedField)
            Entry("BIN", entryType: .bin, text: $store.binText.sending(\.binTextChanged), focusedField: _focusedField)
        }
        .padding()
        .toolbar{
            Picker("", selection: $store.bits.sending(\.selectedBitWidthChanged)) {
                Text("8").tag(Bits._8)
                Text("16").tag(Bits._16)
                Text("32").tag(Bits._32)
                Text("64").tag(Bits._64)
            }
            .pickerStyle(.segmented)
        }
        .frame(minWidth: 450, idealWidth: store.idealWidth, maxWidth: 730)
        .onAppear { store.send(.onAppear) }
        .onChange(of: store.idealWidth, initial: true) { old, new in
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
