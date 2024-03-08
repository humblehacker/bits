import ComposableArchitecture
import SwiftUI
import UI

struct BinaryTextEntry: View {
    @Bindable var store: StoreOf<EntryReducer>

    var body: some View {
        logChanges()

        return BinaryTextField(
            text: $store.text,
            store: store.scope(state: \.binText, action: \.binText)!
        )
        .entryTextStyle()
        .focusEffectDisabled()
        .task { store.send(.task) }
    }
}

#Preview {
    BinaryTextEntry(
        store: Store(initialState: .init(.bin, value: Shared(.init()))) {
            EntryReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
        }
    )
    .padding()
    .frame(maxWidth: .infinity)
}
