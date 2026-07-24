//
//  ExpressCheckoutElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

/// An express checkout element backed by a Checkout Session.
///
/// Obtain an instance from ``Checkout/getExpressCheckoutElement()`` and use
/// ``view`` in SwiftUI or ``uiView`` in UIKit.
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class ExpressCheckoutElement {

    // MARK: - Public Properties

    /// A SwiftUI view that displays the express checkout buttons.
    public internal(set) var view: ExpressCheckoutElementView

    /// A UIKit view that displays the express checkout buttons.
    public internal(set) var uiView: ExpressCheckoutElementUIView

    // MARK: - Internal Properties

    weak var checkout: Checkout?

    // MARK: - Init

    init(checkout: Checkout) {
        self.checkout = checkout
        let uiView = ExpressCheckoutElementUIView(checkout: checkout)
        let viewModel = ExpressCheckoutElementViewModel(checkout: checkout, uiView: uiView)
        self.uiView = uiView
        self.view = ExpressCheckoutElementView(viewModel: viewModel)
    }
}
