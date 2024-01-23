import ComposableArchitecture
import Dependencies
import SwiftUI

struct Entry: View {
    @FocusState var focusedField: FocusedField?

    @State var store: StoreOf<EntryReducer>

    init(store: StoreOf<EntryReducer>) {
        self.store = store
    }

    var body: some View {
        HStack {
            Button(store.title) { focusedField = store.kind }
                .frame(width: 45, height: 20)
                .buttonStyle(.plain)
                .background(buttonBackgroundColor(for: store.kind))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .focusable(false)

            ZStack {
                TextField("", text: $store.text)
                    .entryTextStyle()
                    .focused($focusedField, equals: store.kind)
                    .zIndex(focusedField == store.kind ? 1 : 0)
                    .onKeyPress(keys: [.return, KeyEquivalent("=")]) { _ in
                        store.send(.delegate(.replaceEvaluatedExpression))
                        return .handled
                    }

                Text(store.text)
                    .entryTextStyle()
                    .onTapGesture { focusedField = store.kind }
                    .zIndex(focusedField != store.kind ? 1 : 0)
            }
            .bind($store.focusedField, to: $focusedField)
        }
    }

    func buttonBackgroundColor(for field: FocusedField?) -> Color {
        focusedField == field ? Color.accentColor : Color(nsColor: .controlColor)
    }
}

struct EntryTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .textFieldStyle(.plain)
            .padding([.leading, .trailing], 3)
            .padding([.top, .bottom], 2)
            .background(Color(nsColor: .unemphasizedSelectedTextBackgroundColor))
            .fontDesign(.monospaced)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    func entryTextStyle() -> some View {
        modifier(EntryTextStyle())
    }
}

#Preview {
    Entry(store: Store(initialState: EntryReducer.State(kind: .exp)) {
        EntryReducer()
    })
    .padding()
    .frame(maxWidth: .infinity)
}