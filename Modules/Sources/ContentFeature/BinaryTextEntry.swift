import ComposableArchitecture
import SwiftUI

struct BinaryTextEntry: View {
    @Bindable var store: StoreOf<EntryReducer>

    var body: some View {
        let _ = Self._printChanges()
        if let binStore = store.scope(state: \.binText, action: \.binText) {
            BinaryTextField(text: $store.text, store: binStore)
                .entryTextStyle()
                .focusEffectDisabled()
        }
    }
}

#Preview {
    BinaryTextEntry(
        store: Store(initialState: .init(.bin, binText: .init(bitWidth: ._16))) {
            EntryReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
        }
    )
    .padding()
    .frame(maxWidth: .infinity)
}
