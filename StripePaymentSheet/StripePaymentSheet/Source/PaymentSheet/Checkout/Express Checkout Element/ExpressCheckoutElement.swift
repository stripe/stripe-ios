//
//  ExpressCheckoutElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import SwiftUI

/// A SwiftUI view that displays wallet payment buttons (Apple Pay, Link) for express checkout.
///
/// Obtain this view by calling ``Checkout/getExpressCheckoutElement()`` rather than
/// instantiating it directly. Place it on your cart or checkout page to let customers pay
/// quickly using their saved payment methods.
///
/// ```swift
/// checkout.getExpressCheckoutElement()
/// ```
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public struct ExpressCheckoutElement: View {
    private let checkout: Checkout

    /// Creates an express checkout element.
    /// - Parameter checkout: The ``Checkout`` instance managing the session.
    public init(checkout: Checkout) {
        self.checkout = checkout
    }

    public var body: some View {
        ExpressCheckoutElementRepresentable(checkout: checkout)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - UIViewRepresentable

private struct ExpressCheckoutElementRepresentable: UIViewRepresentable {
    let checkout: Checkout

    func makeUIView(context: Context) -> Checkout.ExpressCheckoutElementView {
        return Checkout.ExpressCheckoutElementView(checkout: checkout)
    }

    func updateUIView(_ uiView: Checkout.ExpressCheckoutElementView, context: Context) {}
}
