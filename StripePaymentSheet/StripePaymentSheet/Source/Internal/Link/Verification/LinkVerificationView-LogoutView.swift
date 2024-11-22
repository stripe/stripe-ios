//
//  LinkVerificationView-LogoutView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 2/4/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension LinkVerificationView {

    final class LogoutView: UIView {
        let linkAccount: PaymentSheetLinkAccountInfoProtocol

        private let font: UIFont = LinkUI.font(forTextStyle: .detail)

        private lazy var label: UILabel = {
            let label = UILabel()
            label.font = font
            label.adjustsFontForContentSizeCategory = true
            label.textColor = .linkSecondaryText
            label.lineBreakMode = .byTruncatingMiddle
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.text = String(
                format: STPLocalizedString(
                    "Not %@?",
                    "Text of a label for confirming an email address. E.g., 'Not user@example.com?'"
                ),
                linkAccount.email
            )
            return label
        }()

        private(set) lazy var button: Button = {
            let button = Button(configuration: .linkPlain(), title: STPLocalizedString(
                "Change email",
                "Title for a button that allows the user to use a different email in the signup flow."
            ))
            button.configuration.font = font
            return button
        }()

        init(linkAccount: PaymentSheetLinkAccountInfoProtocol) {
            self.linkAccount = linkAccount
            super.init(frame: .zero)
            setupUI()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupUI() {
            let stackView = UIStackView(arrangedSubviews: [label, button])
            stackView.spacing = LinkUI.tinyContentSpacing
            stackView.alignment = .center
            stackView.distribution = .equalSpacing
            addAndPinSubview(stackView)
        }
    }

}
