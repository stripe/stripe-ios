//
//  InlineErrorMessageView.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/24/26.
//

@_spi(STP) import StripeUICore
import SwiftUI

/// An inline error message paired with an exclamation icon.
struct InlineErrorMessageView: View {

    /// The error message to display.
    let message: String

    @ScaledMetric(relativeTo: .caption) private var iconSize: CGFloat = 16

    // MARK: - View

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            SwiftUI.Image(uiImage: Image.iconExclamationCircle.makeImage(template: true))
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(.surfaceCritical)
                .accessibilityHidden(true)

            Text(message)
                .typography(.bodySmall)
                .foregroundColor(.textCritical)
                .frame(maxWidth: .infinity, minHeight: iconSize, alignment: .leading)
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Upload error", traits: .sizeThatFitsLayout) {
    InlineErrorMessageView(message: "We couldn’t upload this file. Please try again.")
        .padding(20)
        .background(Color.surfacePrimary)
}

@available(iOS 17.0, *)
#Preview("Multiline error", traits: .sizeThatFitsLayout) {
    InlineErrorMessageView(message: "We couldn’t upload this file. Please try again.")
        .frame(width: 220)
        .padding(20)
        .background(Color.surfacePrimary)
}
#endif
