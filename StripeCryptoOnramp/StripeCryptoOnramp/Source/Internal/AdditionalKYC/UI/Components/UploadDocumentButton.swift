//
//  UploadDocumentButton.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

@_spi(STP) import StripeCore
import SwiftUI

/// An upload action with a configurable format and size hint.
struct UploadDocumentButton: View {

    /// Guidance displayed below the action title, such as accepted formats and file size limits.
    let detail: String

    /// The action that starts document selection.
    let action: () -> Void

    // MARK: - View

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SwiftUI.Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .frame(width: 16)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(attributedTitle)
                        .typography(.bodyLarge)

                    Text(detail)
                        .typography(.bodySmall)
                        .foregroundColor(.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundColor(.textPrimary)
            .padding(16)
            .frame(minHeight: 76)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.documentBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("upload_document")
    }

    // MARK: - UploadDocumentButton

    private var attributedTitle: AttributedString {
        var title = AttributedString(String.Localized.uploadDocument)
        title.underlineStyle = Text.LineStyle(pattern: .dot)
        return title
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Proof of address upload", traits: .sizeThatFitsLayout) {
    UploadDocumentButton(detail: DocumentCollectionConfiguration.preview.uploadHint, action: {})
        .padding(20)
        .background(Color.surfacePrimary)
}

@available(iOS 17.0, *)
#Preview("Source of funds upload", traits: .sizeThatFitsLayout) {
    UploadDocumentButton(detail: DocumentCollectionConfiguration.sourceOfFundsPreview.uploadHint, action: {})
        .padding(20)
        .background(Color.surfacePrimary)
}
#endif
