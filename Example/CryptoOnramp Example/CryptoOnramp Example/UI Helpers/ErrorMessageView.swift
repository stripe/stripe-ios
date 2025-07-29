//
//  ErrorMessageView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import SwiftUI

/// A simple view that displays an error message with a background in shades of red.
struct ErrorMessageView: View {

    /// The error message to display.
    let message: String

    // MARK: - View

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
        ErrorMessageView(message: "Short error message")
        ErrorMessageView(message: "Longer error message demonstrating how the text will wrap once it reaches multiple lines.")
    }
    .padding()
}
