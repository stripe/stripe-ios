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
    public let view: ExpressCheckoutElementView

    /// A UIKit view that displays the express checkout buttons.
    public let uiView: ExpressCheckoutElementUIView

    // MARK: - Init

    init(checkout: Checkout) {
        let uiView = ExpressCheckoutElementUIView(checkout: checkout)
        self.uiView = uiView
        self.view = ExpressCheckoutElementView(uiView: uiView)
    }
}
