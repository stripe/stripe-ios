//
//  WalletHeaderView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 11/9/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
import UIKit

@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

protocol WalletHeaderViewDelegate: AnyObject {
    func walletHeaderViewApplePayButtonTapped(
        _ header: PaymentSheetViewController.WalletHeaderView
    )

    func walletHeaderViewPayWithLinkTapped(
        _ header: PaymentSheetViewController.WalletHeaderView
    )
}

extension PaymentSheetViewController {
    /// A view that looks like:
    ///
    /// [Apple Pay button]
    /// [Link button]
    ///  --- or pay with ---
    ///
    final class WalletHeaderView: UIView {
        struct Constants {
            /// Space between buttons
            static let buttonSpacing: CGFloat = 8
            /// Space between the separator label and the last button
            static let labelSpacing: CGFloat = 24
            /// Height for the Apple Pay button
            static let applePayButtonHeight: CGFloat = 44
        }

        struct WalletOptions: OptionSet {
            let rawValue: Int

            static let applePay = WalletOptions(rawValue: 1 << 0)
            static let link = WalletOptions(rawValue: 1 << 1)
        }

        weak var delegate: WalletHeaderViewDelegate?

        var showsCardPaymentMessage: Bool = false {
            didSet {
                updateSeparatorLabel()
            }
        }

        private let options: WalletOptions
        private let appearance: PaymentSheet.Appearance
        private let applePayButtonType: PKPaymentButtonType
        private let isPaymentIntent: Bool
        private var stackView = UIStackView()

        private lazy var payWithLinkButton: PayWithLinkButton = {
            let button = PayWithLinkButton()
            button.cornerRadius = appearance.cornerRadius
            button.accessibilityIdentifier = "pay_with_link_button"
            button.addTarget(self, action: #selector(handleTapPayWithLink), for: .touchUpInside)
            return button
        }()

        private lazy var separatorLabel = SeparatorLabel()

        private var supportsApplePay: Bool {
            return options.contains(.applePay)
        }

        private var supportsPayWithLink: Bool {
            return options.contains(.link)
        }

        var separatorText: String {
            switch (isPaymentIntent, showsCardPaymentMessage) {
            case (true, true):
                return STPLocalizedString(
                    "Or pay with a card",
                    "Title of a section displayed below an Apple Pay button. The section contains a credit card form as an alternative way to pay.")
            case (true, false):
                return STPLocalizedString(
                    "Or pay using",
                    "Title of a section displayed below an Apple Pay button. The section contains alternative ways to pay.")
            case (false, true):
                return STPLocalizedString(
                    "Or use a card",
                    "Title of a section displayed below an Apple Pay button. The section contains a credit card form as an alternative way to set up.")
            case (false, false):
                return STPLocalizedString(
                    "Or use",
                    "Title of a section displayed below an Apple Pay button. The section contains alternative ways to set up.")
            }
        }

        init(options: WalletOptions,
             appearance: PaymentSheet.Appearance = PaymentSheet.Appearance.default,
             applePayButtonType: PKPaymentButtonType = .plain,
             isPaymentIntent: Bool = true,
             delegate: WalletHeaderViewDelegate?) {
            self.options = options
            self.appearance = appearance
            self.applePayButtonType = applePayButtonType
            self.isPaymentIntent = isPaymentIntent
            self.delegate = delegate
            super.init(frame: .zero)

            buildAndPinStackView()

            updateSeparatorLabel()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func handleTapApplePay() {
            delegate?.walletHeaderViewApplePayButtonTapped(self)
        }

        @objc func handleTapPayWithLink() {
            delegate?.walletHeaderViewPayWithLinkTapped(self)
        }

        private func buildAndPinStackView() {
            stackView.removeFromSuperview()

            var buttons: [UIView] = []

            if supportsApplePay {
                buttons.append(buildApplePayButton())
            }

            if supportsPayWithLink {
                buttons.append(payWithLinkButton)
            }

            stackView = UIStackView(arrangedSubviews: buttons + [separatorLabel])
            stackView.axis = .vertical
            stackView.spacing = Constants.buttonSpacing

            if let lastButton = buttons.last {
                stackView.setCustomSpacing(Constants.labelSpacing, after: lastButton)
            }

            addAndPinSubview(stackView)
        }

        private func buildApplePayButton() -> PKPaymentButton {
            let buttonStyle: PKPaymentButtonStyle = appearance.colors.background.contrastingColor == .black ? .black : .white
            let button = PKPaymentButton(paymentButtonType: applePayButtonType, paymentButtonStyle: buttonStyle)
            button.accessibilityIdentifier = "apple_pay_button"
            button.addTarget(self, action: #selector(handleTapApplePay), for: .touchUpInside)

            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: Constants.applePayButtonHeight)
            ])

            button.cornerRadius = appearance.cornerRadius

            return button
        }

        private func updateSeparatorLabel() {
            separatorLabel.textColor = appearance.colors.textSecondary
            separatorLabel.separatorColor = appearance.colors.background.contrastingColor.withAlphaComponent(0.2)
            separatorLabel.font = appearance.scaledFont(for: appearance.font.base.regular, style: .footnote, maximumPointSize: 21)
            separatorLabel.text = separatorText
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            buildAndPinStackView()
            updateSeparatorLabel()

        }
    }
}

// MARK: - EventHandler
extension PaymentSheetViewController.WalletHeaderView: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            alpha = 1
        case .shouldDisableUserInteraction:
            alpha = 0.8
        default:
            break
        }
    }
}
