//
//  Checkout+CurrencySelectorElement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/8/26.
//

import SwiftUI

#if canImport(UIKit)
private typealias CurrencySelectorPlatformViewRepresentable = UIViewRepresentable
#elseif canImport(AppKit)
private typealias CurrencySelectorPlatformViewRepresentable = NSViewRepresentable
#endif

// MARK: - CurrencySelectorElement (SwiftUI)

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A SwiftUI currency selector for Adaptive Pricing.
    ///
    /// Place this view on your cart or checkout page (near the total price) to let
    /// customers toggle between their local currency and the merchant's currency.
    ///
    /// The view automatically observes the ``Checkout`` session and:
    /// - Hides itself when Adaptive Pricing is not available
    /// - Shows two currency options with formatted amounts and exchange rate disclosure
    /// - Calls ``Checkout.selectCurrency(_:)`` when the customer taps a currency
    ///
    /// ```swift
    /// Checkout.CurrencySelectorElement(checkout: checkout)
    /// ```
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
            // can still occupy space so this check ensures zero layout footprint.
            if isAdaptivePricingAvailable {
                CurrencySelectorViewRepresentable(checkout: checkout, appearance: appearance)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        private var isAdaptivePricingAvailable: Bool {
            return CurrencySelectorUtilities.adaptivePricingData(from: checkout.session) != nil
        }
    }
}

// MARK: - ViewRepresentable

@MainActor
private struct CurrencySelectorViewRepresentable: CurrencySelectorPlatformViewRepresentable {
    let checkout: Checkout
    let appearance: Checkout.CurrencySelectorView.Appearance

    private func makeView(context: Context) -> Checkout.CurrencySelectorView {
        let view = Checkout.CurrencySelectorView(checkout: checkout, appearance: appearance)
        view.isEnabled = context.environment.isEnabled
        return view
    }

    private func updateView(_ view: Checkout.CurrencySelectorView, context: Context) {
        view.isEnabled = context.environment.isEnabled
    }

    #if canImport(UIKit)
    func makeUIView(context: Context) -> Checkout.CurrencySelectorView {
        makeView(context: context)
    }

    func updateUIView(_ uiView: Checkout.CurrencySelectorView, context: Context) {
        updateView(uiView, context: context)
    }
    #elseif canImport(AppKit)
    func makeNSView(context: Context) -> Checkout.CurrencySelectorView {
        makeView(context: context)
    }

    func updateNSView(_ nsView: Checkout.CurrencySelectorView, context: Context) {
        updateView(nsView, context: context)
    }
    #endif
}
