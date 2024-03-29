import SwiftUI
import Types

struct BitsPicker: View {
    @Binding var selection: Bits

    var body: some View {
        Picker(selection: $selection) {
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
