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
                        .padding(.vertical, 8)
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
        .padding([.horizontal, .bottom])
        .toolbar {
            ToolbarItem {
                Text(Bundle.main.appName ?? "")
                    .font(.system(size: 13))
                    .fontWeight(.bold)
            }
            ToolbarItem {
                Spacer()
            }
            ToolbarItem {
                Button(store.value.signage == .signed ? "Signed" : "Unsigned") {
                    store.send(.toggleSignage)
                }
                .font(.body.smallCaps())
            }
            ToolbarItem {
                BitsPicker(selection: $store.selectedBits)
            }
        }
        .fixedSize()
        .onAppear { store.send(.onAppear) }
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
