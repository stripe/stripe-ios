//
//  PrimaryActionButton.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/10/26.
//

@_spi(STP) import StripeCore
@_spi(CryptoOnrampAlpha) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

/// A full-width primary action button styled with the supplied appearance.
struct PrimaryActionButton: View {

    /// The localized button title, also used as its accessibility label.
    let title: String

    /// The appearance supplying the button's colors, height, and corner radius.
    let appearance: LinkAppearance

    /// The closure to invoke when the button is activated.
    let action: () -> Void

    /// Whether the current input permits this action.
    var isEnabled = true

    /// Whether the owner is waiting for this action to complete.
    var isProcessing = false

    // MARK: - View

    var body: some View {
        Button {
            guard isEnabled, !isProcessing else {
                return
            }
            action()
        } label: {
            ZStack {
                Text(title)
                    .typography(.bodyLargeEmphasized)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(isProcessing ? 0 : (isEnabled ? 1 : 0.6))

                if isProcessing {
                    ProgressView()
                        .tint(Color(uiColor: appearance.primaryButtonForeground))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: appearance.primaryButton.resolvedHeight)
            .foregroundColor(Color(uiColor: appearance.primaryButtonForeground))
            .background(Color(uiColor: appearance.primaryButtonBackground))
            .clipShape(RoundedRectangle(cornerRadius: appearance.primaryButton.resolvedCornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: appearance.primaryButton.resolvedCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isProcessing)
        .accessibilityLabel(title)
        .accessibilityValue(isProcessing ? String.Localized.processing : "")
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Primary action", traits: .sizeThatFitsLayout) {
    PrimaryActionButton(
        title: "Continue",
        appearance: .previewLinkAppearance,
        action: {}
    )
    .padding(20)
}

@available(iOS 17.0, *)
#Preview("Default appearance", traits: .sizeThatFitsLayout) {
    PrimaryActionButton(
        title: "Continue",
        appearance: LinkAppearance(),
        action: {}
    )
    .padding(20)
}

@available(iOS 17.0, *)
#Preview("Processing", traits: .sizeThatFitsLayout) {
    PrimaryActionButton(title: "Submit", appearance: .previewLinkAppearance, action: {}, isProcessing: true)
        .padding(20)
}

@available(iOS 17.0, *)
#Preview("Disabled", traits: .sizeThatFitsLayout) {
    PrimaryActionButton(title: "Submit", appearance: .previewLinkAppearance, action: {}, isEnabled: false)
        .padding(20)
}
#endif
