//
//  Checkout+CurrencySelectorSwiftUI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/6/26.
//

@_spi(STP) import StripePayments
import SwiftUI

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// A SwiftUI view that displays a currency selector for Adaptive Pricing.
    ///
    /// Place this view on your cart or checkout page to let customers toggle
    /// between their local currency and the merchant's currency. The view
    /// automatically hides when Adaptive Pricing is not available.
    ///
    /// ```swift
    /// Checkout.CurrencySelectorElement(checkout: checkout)
    /// ```
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
            if shouldShow {
                CurrencySelectorViewRepresentable(checkout: checkout, appearance: appearance)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        private var shouldShow: Bool {
            StripePaymentSheet.CurrencySelectorElement.isAdaptivePricingAvailable(session: checkout.session)
        }
    }
}

// MARK: - UIViewRepresentable

private struct CurrencySelectorViewRepresentable: UIViewRepresentable {
    let checkout: Checkout
    let appearance: Checkout.CurrencySelectorView.Appearance

    func makeUIView(context: Context) -> Checkout.CurrencySelectorView {
        Checkout.CurrencySelectorView(checkout: checkout, appearance: appearance)
    }

    func updateUIView(_ uiView: Checkout.CurrencySelectorView, context: Context) {
        // The view self-updates via Combine observation of checkout.$session.
    }
}
