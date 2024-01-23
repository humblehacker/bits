import ComposableArchitecture
import Dependencies
import SwiftUI

struct HistoryPicker: View {
    let store: StoreOf<HistoryReducer>

    @State var selection: Int = 0
    var body: some View {
        List(selection: $selection) {
            Text("Foo").tag(0)
            Text("Bar").tag(1)
            Text("Baz").tag(2)
        }
        .onKeyPress(.return) {
            store.send(.historySelected)
            return .handled
        }
    }
}

@Reducer
public struct HistoryReducer {
    @Dependency(\.dismiss) var dismiss

    public struct State: Equatable {
        var history: [String] = []
    }

    public enum Action: Equatable {
        case historySelected
    }

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .historySelected:
                return .run { _ in await dismiss() }
            }
        }
    }
}
