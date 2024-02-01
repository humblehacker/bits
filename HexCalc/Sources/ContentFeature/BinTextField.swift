import ComposableArchitecture
import SwiftUI

struct BinTextField: View {
    @Bindable var store: StoreOf<BinTextFieldReducer>

    init(store: StoreOf<BinTextFieldReducer>) {
        self.store = store
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(store.binCharacters, id: \.index) { ic in
                Text("\(ic.character)")
                if ic.index.isMultiple(of: 4) && ic.index != store.bitWidth.rawValue {
                    Text(" ")
                }
            }
        }
        .entryTextStyle()
    }
}

struct BinTextFieldPreviewContainer: View {
    @State var selectedBitWidth: Bits = ._8
    @State var text: String = "0"

    @Bindable var binTextFieldStore = Store(initialState: BinTextFieldReducer.State()) {
        BinTextFieldReducer()
    }

    var body: some View {
        VStack {
            Picker("", selection: $binTextFieldStore.bitWidth) {
                Text("8").tag(Bits._8)
                Text("16").tag(Bits._16)
                Text("32").tag(Bits._32)
                Text("64").tag(Bits._64)
            }
            .pickerStyle(.segmented)

            TextField("", text: $binTextFieldStore.text)

            BinTextField(store: binTextFieldStore)
        }
        .padding()
    }
}

#Preview {
    BinTextFieldPreviewContainer()
        .frame(width: 500)
}
