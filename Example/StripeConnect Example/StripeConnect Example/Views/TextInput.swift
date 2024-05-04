//
//  TextInput.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 5/3/24.
//

import SwiftUI

struct TextInput: View {
    let label: String
    let placeholder: String
    let text: Binding<String>
    private(set) var isValid = true

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
            if !text.wrappedValue.isEmpty && !isFocused && !isValid {
                Text("Invalid value")
                    .foregroundColor(Color(uiColor: .systemRed))
                    .font(.caption)
            }
        }
    }
}
