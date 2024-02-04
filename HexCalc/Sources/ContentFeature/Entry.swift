import ComposableArchitecture
import Dependencies
import HistoryFeature
import SwiftUI

struct Entry<TextFieldContent: View>: View {
    @State var store: StoreOf<EntryReducer>
    let textField: (Binding<String>) -> TextFieldContent

    init(
        store: StoreOf<EntryReducer>,
        @ViewBuilder textField: @escaping (Binding<String>) -> TextFieldContent
    ) {
        self.store = store
        self.textField = textField
    }

    var body: some View {
        HStack {
            Button(store.title) { store.isFocused = true }
                .frame(width: 45, height: 20)
                .buttonStyle(.plain)
                .background(buttonBackgroundColor(store.isFocused))
                .foregroundColor(buttonForegroundColor(store.isFocused))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .focusable(false)

            textField($store.text)
                .entryTextStyle()
                .onKeyPress(keys: [.return, "="]) { _ in
                    store.send(.confirmationKeyPressed)
                    return .handled
                }
        }
    }

    func buttonBackgroundColor(_ isFocused: Bool) -> Color {
        isFocused ? Color.accentColor : Color(nsColor: .controlColor)
    }

    func buttonForegroundColor(_ isFocused: Bool) -> Color {
        isFocused ? Color.white : Color(nsColor: .controlTextColor)
    }
}

extension Entry where TextFieldContent == TextField<Text> {
    init(store: StoreOf<EntryReducer>) {
        self.store = store
        textField = { text in
            TextField("", text: text)
        }
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
    }
}

extension View {
    func entryTextStyle() -> some View {
        modifier(EntryTextStyle())
    }
}

#Preview {
    Entry(
        store: Store(initialState: .init(.bin, text: "0000 0000")) {
            EntryReducer()
        }
    )
    .padding()
    .frame(maxWidth: .infinity)
}
