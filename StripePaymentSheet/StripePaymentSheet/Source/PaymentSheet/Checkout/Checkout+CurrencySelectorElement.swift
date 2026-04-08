//
//  Checkout+CurrencySelectorElement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/8/26.
//

import SwiftUI

/// Capture the internal `CurrencySelectorElement` type before the `Checkout`
/// extension introduces a same-named nested type.
private typealias InternalCurrencySelector = CurrencySelectorElement

// MARK: - CurrencySelectorElement (SwiftUI)

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// A SwiftUI currency selector for Adaptive Pricing.
    ///
    /// Place this view on your cart or checkout page (near the total price) to let
    /// customers toggle between their local currency and the merchant's currency.
    ///
    /// The view automatically observes the ``Checkout`` session and:
    /// - Hides itself when Adaptive Pricing is not available
    /// - Shows two currency options with formatted amounts and exchange rate disclosure
    /// - Calls ``Checkout/selectCurrency(_:)`` when the customer taps a currency
    ///
    /// ```swift
    /// Checkout.CurrencySelectorElement(checkout: checkout)
    /// ```
    @available(iOS 15.0, *)
    @MainActor
    public struct CurrencySelectorElement: View {
        @ObservedObject private var checkout: Checkout
        private let appearance: CurrencySelectorView.Appearance

        /// Creates a currency selector element.
        /// - Parameters:
        ///   - checkout: The ``Checkout`` instance managing the session.
        ///   - appearance: Appearance configuration for the selector.
        public init(
            checkout: Checkout,
            appearance: CurrencySelectorView.Appearance = CurrencySelectorView.Appearance()
        ) {
            self.checkout = checkout
            self.appearance = appearance
        }

        public var body: some View {
            // Remove the view from SwiftUI layout entirely when AP is unavailable.
            // The UIView hides itself internally, but a hidden UIViewRepresentable
            // can still occupy space — this guard ensures zero layout footprint.
            if InternalCurrencySelector.adaptivePricingData(from: checkout.state.session) != nil {
                CurrencySelectorViewRepresentable(checkout: checkout, appearance: appearance)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - UIViewRepresentable Bridge

@available(iOS 15.0, *)
private struct CurrencySelectorViewRepresentable: UIViewRepresentable {
    let checkout: Checkout
    let appearance: Checkout.CurrencySelectorView.Appearance

    func makeUIView(context: Context) -> Checkout.CurrencySelectorView {
        let view = Checkout.CurrencySelectorView(checkout: checkout, appearance: appearance)
        // Forward SwiftUI's .disabled() modifier to the UIKit view.
        view.isEnabled = context.environment.isEnabled
        return view
    }

    func updateUIView(_ uiView: Checkout.CurrencySelectorView, context: Context) {
        uiView.isEnabled = context.environment.isEnabled
    }
}
