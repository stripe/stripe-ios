//
//  ExpressCheckoutElementView.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import UIKit

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A UIKit view that displays wallet payment buttons (Apple Pay, Link).
    @MainActor
    public final class ExpressCheckoutElementView: UIView {

        // MARK: - Private Properties

        private let checkout: Checkout

        // MARK: - Init

        /// Creates an express checkout element view.
        /// - Parameter checkout: The ``Checkout`` instance managing the session.
        public init(checkout: Checkout) {
            self.checkout = checkout
            super.init(frame: .zero)

            handleSessionUpdate()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Methods

        private func handleSessionUpdate() {
            let buttons = Self.expressButtons(
                from: checkout.session,
                configuration: checkout.configuration
            )
            configure(buttons: buttons)
        }

        private func configure(buttons: [ExpressButton]) {
            // TODO: Render express buttons
        }
    }
}

// MARK: - Button Computation

extension Checkout.ExpressCheckoutElementView {
    /// Returns the express buttons to display for the given session and configuration.
    static func expressButtons(
        from session: Checkout.Session,
        configuration: Checkout.Configuration
    ) -> [ExpressButton] {
        // TODO: Compute from elements session
        return []
    }
}
