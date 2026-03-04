//
//  FormField.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/7/25.
//

import SwiftUI

/// Convenience `View` that wraps a field on a form with a `headline` title.
struct FormField<Content: View>: View {
    private let title: Text

    @ViewBuilder
    private let content: () -> Content

    /// Creates a new `FormField`.
    /// - Parameters:
    ///   - title: The title displayed above the field.
    ///   - content: The content of the field itself.
    init(_ title: Text, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    /// Creates a new `FormField`.
    /// - Parameters:
    ///   - title: The localized title displayed above the field.
    ///   - content: The content of the field itself.
    init(_ title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.init(Text(title), content: content)
    }

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            title
                .font(.headline)

            content()
        }
    }
}
