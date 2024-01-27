import ComposableArchitecture
import Dependencies
import SwiftUI
import UI

private let historyListPadding = 4.0
private let maxVisibleHistoryItems = 5

public struct HistoryPicker: View {
    @State var selection: Int?
    @Bindable var store: StoreOf<HistoryReducer>
    @State var rowHeight: Double = 0

    public init(store: StoreOf<HistoryReducer>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(nsColor: .controlBackgroundColor).scaleEffect(1.5)

            ScrollViewReader { scroller in
                List(store.history, selection: $selection) { item in
                    Text(item.text)
                        .listRowSeparator(.hidden)
                        .overlay {
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    rowHeight = geo.size.height + UIDefault.List.rowSpacing
                                }
                            }
                        }
                }
                .onChange(of: store.history, initial: true) {
                    guard let last = store.history.last else { return }
                    selection = last.id
                    scroller.scrollTo(last.id, anchor: .bottom)
                }
            }
            .padding(historyListPadding)
        }
        .onKeyPress(.return) {
            store.send(.historySelected)
            return .handled
        }
        .frame(height: frameHeight)
    }

    var frameHeight: Double {
        let visibleItems = min(maxVisibleHistoryItems, store.history.count)
        return rowHeight * Double(visibleItems)
            + 2 * historyListPadding
            + 2 * UIDefault.List.internalPadding
    }
}

#Preview {
    HistoryPicker(
        store: Store(
            initialState: HistoryReducer.State(
                history: [
                    "Foo", "Bar", "Baz", "Qux", "Quux", "Corge", "Grault", "Garply", "Waldo", "Fred", "Plugh", "Xyzzy", "Thud",
                ]
                .enumerated()
                .map { HistoryItem(id: $0.0, text: $0.1) }
                .reversed()
            )
        ) {
            HistoryReducer()
        }
    )
}
