//
//  ExpressCheckoutElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import SwiftUI

/// A SwiftUI view that displays wallet payment buttons (Apple Pay, Link) for express checkout.
///
/// Place this view on your cart or checkout page to let customers pay quickly using their
/// saved payment methods.
///
/// ```swift
/// ExpressCheckoutElement(checkout: checkout)
/// ```
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public struct ExpressCheckoutElement: View {
    private let checkout: Checkout
    private let appearance: Checkout.ExpressCheckoutElementView.Appearance

    /// Creates an express checkout element.
    /// - Parameters:
    ///   - checkout: The ``Checkout`` instance managing the session.
    ///   - appearance: Visual customization for the element's buttons.
    public init(
        checkout: Checkout,
        appearance: Checkout.ExpressCheckoutElementView.Appearance = .init()
    ) {
        self.checkout = checkout
        self.appearance = appearance
    }

    public var body: some View {
        ExpressCheckoutElementRepresentable(checkout: checkout, appearance: appearance)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - UIViewRepresentable

private struct ExpressCheckoutElementRepresentable: UIViewRepresentable {
    let checkout: Checkout
    let appearance: Checkout.ExpressCheckoutElementView.Appearance

    func makeUIView(context: Context) -> Checkout.ExpressCheckoutElementView {
        return Checkout.ExpressCheckoutElementView(checkout: checkout, appearance: appearance)
    }

    func updateUIView(_ uiView: Checkout.ExpressCheckoutElementView, context: Context) {}
}
