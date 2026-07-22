//
//  ExpressCheckoutElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/21/26.
//

import SwiftUI

/// An element that displays express checkout wallet buttons (Apple Pay, Link).
///
/// ```swift
/// ExpressCheckoutElement(checkout: checkout) { type in
///     // handle wallet tap
/// }
/// ```
@_spi(STP)
@MainActor
public struct ExpressCheckoutElement: View {

    private let checkout: Checkout
    private let onWalletTapped: ((ExpressButtonType) -> Void)?

    /// Creates an express checkout element.
    /// - Parameters:
    ///   - checkout: The ``Checkout`` instance managing the session.
    ///   - onWalletTapped: Called when the user taps a wallet button.
    public init(
        checkout: Checkout,
        onWalletTapped: ((ExpressButtonType) -> Void)? = nil
    ) {
        self.checkout = checkout
        self.onWalletTapped = onWalletTapped
    }

    public var body: some View {
        ExpressCheckoutElementRepresentable(checkout: checkout, onWalletTapped: onWalletTapped)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - UIViewRepresentable

private struct ExpressCheckoutElementRepresentable: UIViewRepresentable {
    let checkout: Checkout
    let onWalletTapped: ((ExpressButtonType) -> Void)?

    func makeUIView(context: Context) -> Checkout.ExpressCheckoutElementUIView {
        let view = Checkout.ExpressCheckoutElementUIView(checkout: checkout)
        view.onWalletTapped = onWalletTapped
        return view
    }

    func updateUIView(_ uiView: Checkout.ExpressCheckoutElementUIView, context: Context) {
        uiView.onWalletTapped = onWalletTapped
    }
}
