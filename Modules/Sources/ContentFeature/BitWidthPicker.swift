import SwiftUI

struct BitWidthPicker: View {
    @Binding var selectedBitWidth: Bits

    var body: some View {
        Picker(selection: $selectedBitWidth) {
            ForEach(Bits.allCases) { bit in
                Text("\(bit.rawValue)")
                    .tag(bit)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
    }
}
