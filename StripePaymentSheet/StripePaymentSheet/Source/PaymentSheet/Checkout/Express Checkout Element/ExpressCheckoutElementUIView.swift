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

    private weak var delegate: ExpressCheckoutElementDelegate?

    init(session: Checkout.Session, configuration: Checkout.Configuration, delegate: ExpressCheckoutElementDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        // TODO: Render express buttons
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with session: Checkout.Session) {
        // TODO: Re-render express buttons
    }
}
