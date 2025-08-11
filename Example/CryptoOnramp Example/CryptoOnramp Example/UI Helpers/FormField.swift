//
//  FormField.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/7/25.
//

import SwiftUI

/// Convenience `View` that wraps a field on a form with a `headline` title.
struct FormField<Content: View>: View {
    private let title: String

    @ViewBuilder
    private let content: () -> Content

    /// Creates a new `FormField`.
    /// - Parameters:
    ///   - title: The title displayed above the field.
    ///   - content: The content of the field itself.
    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            content()
        }
    }
}
