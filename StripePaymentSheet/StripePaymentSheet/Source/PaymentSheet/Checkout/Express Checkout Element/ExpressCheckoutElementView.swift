//
//  ExpressCheckoutElementView.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit
@_spi(STP) import StripeCore
import UIKit

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A UIKit view that displays wallet payment buttons (Apple Pay, Link).
    @MainActor
    public final class ExpressCheckoutElementView: UIView {

        // MARK: - Private Properties

        private let checkout: Checkout
        private let appearance: Appearance
        private let stackView = UIStackView()

        // MARK: - Init

        /// Creates an express checkout element view.
        /// - Parameters:
        ///   - checkout: The ``Checkout`` instance managing the session.
        ///   - appearance: Visual customization for the element's buttons.
        public init(checkout: Checkout, appearance: Appearance = .init()) {
            self.checkout = checkout
            self.appearance = appearance
            super.init(frame: .zero)

            stackView.axis = .vertical
            stackView.spacing = appearance.buttonSpacing
            stackView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

            configure(buttons: Self.expressButtons(
                from: checkout.session,
                configuration: checkout.configuration
            ))
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Methods

        public override var intrinsicContentSize: CGSize {
            CGSize(
                width: UIView.noIntrinsicMetric,
                height: stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            )
        }

        // MARK: - Private Methods

        private func configure(buttons: [ExpressButton]) {
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            buttons.forEach { stackView.addArrangedSubview(makeButton(for: $0)) }
            invalidateIntrinsicContentSize()
        }

        private func makeButton(for button: ExpressButton) -> UIView {
            switch button {
            case .applePay:
                return makeApplePayButton()
            case .link:
                return makeLinkButton()
            }
        }

        private func makeApplePayButton() -> UIView {
            let buttonType = checkout.configuration.applePayConfiguration?.buttonType ?? .plain
            let button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: .automatic)
            button.cornerRadius = appearance.cornerRadius
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: appearance.buttonHeight).isActive = true
            button.addTarget(self, action: #selector(handleApplePayTapped), for: .touchUpInside)
            return button
        }

        private func makeLinkButton() -> UIView {
            let button = PayWithLinkButton()
            button.cornerRadius = appearance.cornerRadius
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: appearance.buttonHeight).isActive = true
            button.addTarget(self, action: #selector(handleLinkTapped), for: .touchUpInside)
            return button
        }

        @objc private func handleApplePayTapped() {
            // TODO: Handle Apple Pay
        }

        @objc private func handleLinkTapped() {
            // TODO: Handle Link
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
        let eceConfig = configuration.expressCheckoutElement
        var buttons: [ExpressButton] = []
        for button in session.availableExpressButtonTypes {
            switch button {
            case .applePay:
                if eceConfig.applePay != .never,
                    configuration.applePayConfiguration != nil,
                    StripeAPI.deviceSupportsApplePay() {
                    buttons.append(.applePay)
                }
            case .link:
                if eceConfig.link != .never
                    && configuration.linkConfiguration?.display != .never {
                    buttons.append(.link)
                }
            }
        }

        // .always: include even if the session does not advertise the wallet
        if eceConfig.applePay == .always,
            configuration.applePayConfiguration != nil,
            StripeAPI.deviceSupportsApplePay(),
            !buttons.contains(.applePay) {
            buttons.append(.applePay)
        }
        if eceConfig.link == .always,
            !buttons.contains(.link) {
            buttons.append(.link)
        }

        return buttons
    }
}
