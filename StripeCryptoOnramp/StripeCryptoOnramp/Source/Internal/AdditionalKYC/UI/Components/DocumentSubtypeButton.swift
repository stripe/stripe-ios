//
//  DocumentSubtypeButton.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

@_spi(STP) import StripeCore
import SwiftUI

/// Opens the document subtype picker, displaying its label and committed selection.
struct DocumentSubtypeButton: View {

    /// The field label displayed above the selection.
    let title: String

    /// The selected category's label.
    let selection: String

    /// The action that opens the document subtype picker.
    let action: () -> Void

    // MARK: - View

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .typography(.bodySmall)
                        .foregroundColor(.textTertiary)

                    Text(selection)
                        .typography(.bodyLarge)
                        .foregroundColor(.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                SwiftUI.Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 56)
            .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(selection)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Document subtype selections", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        DocumentSubtypeButton(title: .Localized.documentType, selection: "Utility bill", action: {})

        DocumentSubtypeButton(title: .Localized.documentType, selection: "Government-issued proof of residential address", action: {})
    }
    .padding(20)
    .background(Color.surfacePrimary)
}
#endif
