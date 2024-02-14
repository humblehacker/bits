import SwiftUI

struct BitWidthPicker: View {
    @Binding var selectedBitWidth: Bits

    var body: some View {
        Picker(selection: $selectedBitWidth) {
            Text("8").tag(Bits._8)
            Text("16").tag(Bits._16)
            Text("32").tag(Bits._32)
            Text("64").tag(Bits._64)
        } label: { EmptyView() }
            .pickerStyle(.segmented)
    }
}
