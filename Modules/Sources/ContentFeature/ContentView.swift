import ComposableArchitecture
import HistoryFeature
import SwiftUI
import UI

public struct ContentView: View {
    @State var store: StoreOf<ContentReducer>
    @FocusState var focusedField: EntryKind?

    public init(store: StoreOf<ContentReducer>) {
        self.store = store
    }

    public var body: some View {
        logChanges()

        return VStack {
            BinaryTextEntry(store: store.scope(entryKind: .bin))
                .padding(.vertical, 8)
                .focused($focusedField, equals: .bin)
                .onTapGesture { focusedField = .bin }

            Entry(store: store.scope(entryKind: .exp))
                .focused($focusedField, equals: .exp)
                .onKeyPress(.upArrow) {
                    store.send(.upArrowPressed)
                    return .handled
                }
                .overlay {
                    GeometryReader { geo in
                        Color.clear.onAppear { store.entryWidth = geo.size.width }
                    }
                }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(store.scope(state: \.variableEntries, action: \.entries)) { store in
                    Entry(store: store)
                        .focused($focusedField, equals: store.kind)
                }
            }
        }
        .padding([.horizontal, .bottom])
        .toolbar { Toolbar(store: store) }
        .fixedSize()
        .onAppear { store.send(.onAppear) }
        .popover(item: $store.scope(state: \.destination?.history, action: \.destination.history)) { store in
            HistoryPicker(store: store)
                .frame(width: self.store.entryWidth)
        }
        .bind($store.focusedField, to: $focusedField)
    }
}

struct Toolbar: ToolbarContent {
    @Bindable var store: StoreOf<ContentReducer>

    var body: some ToolbarContent {
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
}

extension StoreOf<ContentReducer> {
    func scope(entryKind: EntryKind) -> StoreOf<EntryReducer> {
        scope(state: \.entries[id: entryKind]!, action: \.entries[id: entryKind])
    }
}

#Preview {
    ContentView(store: Store(initialState: .init(value: .init())) {
        ContentReducer()
    })
}
