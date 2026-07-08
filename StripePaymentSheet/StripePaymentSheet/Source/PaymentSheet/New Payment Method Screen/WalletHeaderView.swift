//
//  WalletHeaderView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 11/9/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
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
        private let walletAppearance: PaymentSheet.Appearance
        private let applePayButtonType: PKPaymentButtonType
        private let isPaymentIntent: Bool
        private let linkBrandProvider: () -> LinkBrand
        private var linkBrand: LinkBrand {
            didSet {
                guard oldValue != linkBrand else {
                    return
                }
                payWithLinkButton.brand = linkBrand
            }
        }
        private var stackView = UIStackView()
        private var linkAccountObserver: LinkAccountContextObserver?

        private lazy var payWithLinkButton: PayWithLinkButton = {
            let button = PayWithLinkButton(brand: linkBrand)
            if walletAppearance.cornerRadius == nil, LiquidGlassDetector.isEnabledInMerchantApp {
                button.ios26_applyCapsuleCornerConfiguration()
            } else {
                button.cornerRadius = walletAppearance.cornerRadius ?? PaymentSheet.Appearance.defaultCornerRadius
            }
            button.accessibilityIdentifier = "pay_with_link_button"
            button.addTarget(self, action: #selector(handleTapPayWithLink), for: .touchUpInside)
            return button
        }()

        private var isApplePayLastButton: Bool = false

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
             appearance: PaymentSheet.Appearance,
             applePayButtonType: PKPaymentButtonType = .plain,
             linkBrand: LinkBrand = .link,
             linkBrandProvider: (() -> LinkBrand)? = nil,
             isPaymentIntent: Bool = true,
             delegate: WalletHeaderViewDelegate?) {
            self.options = options
            self.walletAppearance = appearance
            self.applePayButtonType = applePayButtonType
            self.linkBrand = linkBrand
            self.linkBrandProvider = linkBrandProvider ?? { linkBrand }
            self.isPaymentIntent = isPaymentIntent
            self.delegate = delegate
            super.init(frame: .zero)

            buildAndPinStackView()
            linkAccountObserver = LinkAccountContextObserver { [weak self] _ in
                DispatchQueue.main.async {
                    self?.syncLinkBrand()
                }
            }
            _ = linkAccountObserver

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

        private func syncLinkBrand() {
            linkBrand = linkBrandProvider()
        }

        private func buildAndPinStackView() {
            var buttons: [UIView] = []

            let applePayButton = createApplePayButton()
            if supportsApplePay {
                buttons.append(applePayButton)
            }

            if supportsPayWithLink {
                buttons.append(payWithLinkButton)
            }

            stackView = UIStackView(arrangedSubviews: buttons + [separatorLabel])
            stackView.axis = .vertical
            stackView.spacing = Constants.buttonSpacing

            if let lastButton = buttons.last {
                stackView.setCustomSpacing(Constants.labelSpacing, after: lastButton)
                isApplePayLastButton = lastButton == applePayButton
            }

            addAndPinSubview(stackView)
        }
        private func regenerateApplePayButton() {

            // Find the Apple Pay button currently in the stackview
            guard let existingButtonIndex = stackView.arrangedSubviews.firstIndex(where: { view in
                view.accessibilityIdentifier == "apple_pay_button"
            }) else {
                return
            }
            let existingButton = stackView.arrangedSubviews[existingButtonIndex]

            // Remove old button
            existingButton.removeFromSuperview()
            stackView.removeArrangedSubview(existingButton)

            // Create fresh button with correct style
            let newButton = createApplePayButton()
            stackView.insertArrangedSubview(newButton, at: existingButtonIndex)
            if isApplePayLastButton {
                stackView.setCustomSpacing(Constants.labelSpacing, after: newButton)
            }
        }

        private func createApplePayButton() -> UIView {
            let isBlackApplePayButton = walletAppearance.colors.background.contrastingColor == .black
            #if canImport(UIKit)
            let button = PKPaymentButton(paymentButtonType: applePayButtonType, paymentButtonStyle: isBlackApplePayButton ? .black : .white)
            #else
            let button = UIButton(type: .system)
            button.setTitle("Apple Pay", for: .normal)
            button.backgroundColor = isBlackApplePayButton ? .black : .white
            #endif
            // The corner configuration API that powers ios26_applyDefaultCornerConfiguration doesn't work on PKPaymentButton
            // Instead, we set the cornerRadius directly to half the button height to emulate the behavior
            // TODO(gbirch): align Apple Pay button liquid glass styling with other elements
            let cornerRadius: CGFloat
            if walletAppearance.cornerRadius == nil, LiquidGlassDetector.isEnabledInMerchantApp {
                cornerRadius = Constants.applePayButtonHeight / 2
            } else {
                cornerRadius = walletAppearance.cornerRadius ?? PaymentSheet.Appearance.defaultCornerRadius
            }
            #if canImport(UIKit)
            button.cornerRadius = cornerRadius
            #else
            button.wantsLayer = true
            button.layer?.cornerRadius = cornerRadius
            #endif

            button.accessibilityIdentifier = "apple_pay_button"
            button.addTarget(self, action: #selector(handleTapApplePay), for: .touchUpInside)

            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: Constants.applePayButtonHeight),
            ])
            return button
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil, supportsApplePay else { return }
            // Recreate the currently visible button to fix iOS 26.2 rendering bug where the Apple Pay button, despite its frame width being correct, renders less wide than it should, *only* reproducible when the Link modal is shown first :|
            regenerateApplePayButton()
        }

        private func updateSeparatorLabel() {
            separatorLabel.textColor = walletAppearance.colors.textSecondary
            separatorLabel.separatorColor = walletAppearance.colors.background.contrastingColor.withAlphaComponent(0.2)
            separatorLabel.font = walletAppearance.scaledFont(for: walletAppearance.font.base.regular, style: .footnote, maximumPointSize: 21)
            separatorLabel.text = separatorText
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            regenerateApplePayButton()
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
