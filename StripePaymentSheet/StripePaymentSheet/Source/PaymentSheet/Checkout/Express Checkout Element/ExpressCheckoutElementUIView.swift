//
//  ExpressCheckoutElementUIView.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit
@_spi(STP) import StripeCore
import UIKit

/// A UIKit view that displays wallet payment buttons (Apple Pay, Link).
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class ExpressCheckoutElementUIView: UIView {

    // MARK: - Private Properties

    private weak var checkout: Checkout?
    private let stackView = UIStackView()

    // MARK: - Init

    init(checkout: Checkout) {
        self.checkout = checkout
        super.init(frame: .zero)

        // TODO: Appearance
        stackView.axis = .vertical
        stackView.spacing = 8
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
        let buttonType = checkout?.configuration.applePayConfiguration?.buttonType ?? .plain
        let button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: .automatic)
        // TODO: Appearance
        button.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(handleApplePayTapped), for: .touchUpInside)
        return button
    }

    private func makeLinkButton() -> UIView {
        let button = PayWithLinkButton()
        // TODO: Appearance
        button.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
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

// MARK: - Button Computation

extension ExpressCheckoutElementUIView {
    static func expressButtons(
        from session: Checkout.Session,
        configuration: Checkout.Configuration
    ) -> [ExpressButton] {
        var buttons: [ExpressButton] = []
        for button in session.availableExpressButtonTypes {
            switch button {
            case .applePay:
                if configuration.applePayConfiguration != nil
                    && StripeAPI.deviceSupportsApplePay() {
                    buttons.append(.applePay)
                }
            case .link:
                buttons.append(.link)
            }
        }
        return buttons
    }
}
