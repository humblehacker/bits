import ComposableArchitecture
import SwiftUI

struct BinaryTextEntry: View {
    @Bindable var store: StoreOf<EntryReducer>

    var body: some View {
        Entry(store: store) { text in
            let _ = Self._printChanges()
            if let binStore = store.scope(state: \.binText, action: \.binText) {
                BinaryTextField(text: text, store: binStore)
            }
        }
    }
}

#Preview {
    BinaryTextEntry(
        store: Store(initialState: .init(.bin, binText: .init())) {
            EntryReducer()
        }
    )
    .padding()
    .frame(maxWidth: .infinity)
}
