import ComposableArchitecture
import SwiftUI

struct BinTextField: View {
    @Bindable var store: StoreOf<BinTextFieldReducer>

    init(store: StoreOf<BinTextFieldReducer>) {
        self.store = store
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1 ... store.bitWidth.rawValue, id: \.self) { value in
                Text("\(0)")
                if value.isMultiple(of: 4) && value != store.bitWidth.rawValue {
                    Text(" ")
                }
            }
        }
        .entryTextStyle()
    }
}

#Preview {
    BinTextField(store: Store(initialState: BinTextFieldReducer.State()) {
        BinTextFieldReducer()
    })
    .padding()
    .frame(width: 500)
}
