//
//  TextInput.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 8/28/24.
//

import SwiftUI

struct TextInput: View {
    let label: Text
    let placeholder: String
    @Binding var text: String
    private(set) var isValid = true

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading) {
            label
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
            if !text.isEmpty && !isFocused && !isValid {
                Text("Invalid value")
                    .foregroundColor(Color(uiColor: .systemRed))
                    .font(.caption)
            }
        }
    }
}

extension TextInput {
    init(label: String,
         placeholder: String,
         text: Binding<String>,
         isValid: Bool = true) {
        self.init(label: Text(label),
                  placeholder: placeholder,
                  text: text,
                  isValid: isValid)
    }
}
