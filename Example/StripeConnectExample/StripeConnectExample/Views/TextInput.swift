//
//  TextInput.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 8/28/24.
//

import SwiftUI

struct TextInput: View {
    enum Constants {
        static let typingTimer = 1.0
    }
    let label: Text
    let placeholder: String
    @Binding var text: String
    private(set) var isValid = true
    @FocusState private var isFocused: Bool
    @State private var typingTimerTriggered = false
    @State private var typingTimer: Timer?

    var body: some View {
        VStack(alignment: .leading) {
            label
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .focused($isFocused)
                .onChange(of: text) { _ in
                    resetTypingTimer()
                }
            if (typingTimerTriggered || !isFocused) && !isValid {
                Text("Invalid value")
                    .foregroundColor(Color(uiColor: .systemRed))
                    .font(.caption)
            }
        }
    }

    private func resetTypingTimer() {
        typingTimerTriggered = false
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: Constants.typingTimer, repeats: false) { _ in
            typingTimerTriggered = true
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
