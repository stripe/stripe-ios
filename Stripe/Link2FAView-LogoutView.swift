//
//  Link2FAView-LogoutView.swift
//  StripeiOS
//
//  Created by Ramon Torres on 2/4/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension Link2FAView {

    final class LogoutView: UIView {
        let linkAccount: PaymentSheetLinkAccountInfoProtocol

        private let font: UIFont = LinkUI.font(forTextStyle: .detail)

        private lazy var label: UILabel = {
            let label = UILabel()
            label.font = font
            label.adjustsFontForContentSizeCategory = true
            label.textColor = CompatibleColor.secondaryLabel
            label.lineBreakMode = .byTruncatingMiddle
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            // TODO(ramont): Localize
            label.text = String(format: "Not %@?", linkAccount.email)
            return label
        }()

        private(set) lazy var button: Button = {
            // TODO(ramont): Localize.
            let button = Button(configuration: .linkPlain(), title: "Change email")
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
