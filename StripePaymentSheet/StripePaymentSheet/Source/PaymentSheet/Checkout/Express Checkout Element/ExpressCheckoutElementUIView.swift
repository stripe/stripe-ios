//
//  ExpressCheckoutElementUIView.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import UIKit

/// A UIKit view that displays wallet payment buttons (Apple Pay, Link).
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class ExpressCheckoutElementUIView: UIView {

    private let checkout: Checkout

    init(checkout: Checkout) {
        self.checkout = checkout
        super.init(frame: .zero)
        // TODO: Render express buttons
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ExpressCheckoutElementUIView {
    static func expressButtons(
        from session: Checkout.Session,
        configuration: Checkout.Configuration
    ) -> [ExpressButton] {
        // TODO: Compute from elements session
        return []
    }
}
