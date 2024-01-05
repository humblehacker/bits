//
//  Entry.swift
//  Calc
//
//  Created by David Whetstone on 1/5/24.
//

import SwiftUI

struct Entry: View {
    let title: String
    let entryType: FocusedField
    @Binding var text: String
    @FocusState var focusedField: FocusedField?

    init(_ title: String, entryType: FocusedField, text: Binding<String>, focusedField: FocusState<FocusedField?>) {
        self.title = title
        self.entryType = entryType
        self._text = text
        self._focusedField = focusedField
    }

    var body: some View {
        HStack {
            Button(title) { focusedField = entryType }
                .frame(width: 45, height: 20)
                .buttonStyle(.plain)
                .background(buttonBackgroundColor(for: entryType))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .focusable(false)

            ZStack {
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .padding([.leading, .trailing], 3)
                    .padding([.top, .bottom], 2)
                    .background(Color(nsColor: .unemphasizedSelectedTextBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .fontDesign(.monospaced)
                    .focused($focusedField, equals: entryType)
                    .zIndex(focusedField == entryType ? 1 : 0)
                    .frame(maxWidth: .infinity)

                Text(text)
                    .lineLimit(1)
                    .padding([.leading, .trailing], 3)
                    .padding([.top, .bottom], 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .background(Color(nsColor: .unemphasizedSelectedTextBackgroundColor))
                    .fontDesign(.monospaced)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .onTapGesture { focusedField = entryType }
                    .zIndex(focusedField != entryType ? 1 : 0)
            }
        }
    }

    func buttonBackgroundColor(for field: FocusedField?) -> Color {
        focusedField == field ? Color.accentColor: Color(nsColor: .controlColor)
    }
}

#Preview {
    Entry("FOO", entryType: .bin, text: .constant("0"), focusedField: FocusState<FocusedField?>())
        .padding()
        .frame(maxWidth: .infinity)
}
