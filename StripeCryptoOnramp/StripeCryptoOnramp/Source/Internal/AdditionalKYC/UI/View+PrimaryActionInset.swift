//
//  View+PrimaryActionInset.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/1/26.
//

@_spi(CryptoOnrampAlpha) import StripePaymentSheet
import SwiftUI

extension View {

    /// Adds a primary action button in the bottom safe area, with padding and a divider above it.
    /// - Parameters:
    ///   - title: The localized button title.
    ///   - appearance: The appearance supplying the button's colors, height, and corner radius.
    ///   - action: The closure invoked when the button is activated.
    ///   - isEnabled: Whether the current input permits the action.
    ///   - isProcessing: Whether the action is in progress and the button should display a loading indicator.
    /// - Returns: The view with the primary action inset attached.
    func primaryActionInset(
        title: String,
        appearance: LinkAppearance,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        isProcessing: Bool = false
    ) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                    .modifier(PrimaryActionDividerInsetModifier())

                PrimaryActionButton(title: title, appearance: appearance, action: action, isEnabled: isEnabled, isProcessing: isProcessing)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .background(Color.surfacePrimary)
            }
        }
    }
}

private struct PrimaryActionDividerInsetModifier: ViewModifier {
    @Environment(\.self) private var environment

    func body(content: Content) -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            // For iPhone Duo support, don't use a full-width separator above the CTA in the presence
            // of a vertical toolbar. Instead, we match the CTA's insets.
            content
                .padding(.horizontal, environment.toolbarVerticalEdge == nil ? 0 : 20)
        } else {
            content
        }
        #else
        content
        #endif
    }
}
