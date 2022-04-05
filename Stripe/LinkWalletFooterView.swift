//
//  LinkWalletFooterView.swift
//  StripeiOS
//
//  Created by Ramon Torres on 10/27/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_LinkWalletFooterView)
final class LinkWalletFooterView: UIView {

    weak var coordinator: PayWithLinkCoordinating?

    /// Font to use for all footer elements.
    private let font: UIFont = LinkUI.font(forTextStyle: .detail)

    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.font = font
        label.adjustsFontForContentSizeCategory = true
        label.textColor = CompatibleColor.secondaryLabel
        label.lineBreakMode = .byTruncatingMiddle
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var separator: UILabel = {
        let label = UILabel()
        label.text = "•"
        label.font = font
        label.adjustsFontForContentSizeCategory = true
        label.textColor = CompatibleColor.secondaryLabel
        label.isAccessibilityElement = false
        return label
    }()

    private lazy var logoutButton: Button = {
        // TODO(ramont): Localize.
        let button = Button(configuration: .linkPlain(), title: "Log out")
        button.addTarget(self, action: #selector(logoutTapped(_:)), for: .touchUpInside)
        button.configuration.font = font
        return button
    }()

    var linkAccount: PaymentSheetLinkAccountInfoProtocol? {
        didSet {
            update()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let stackView = UIStackView(arrangedSubviews: [
            emailLabel,
            separator,
            logoutButton
        ])

        stackView.spacing = LinkUI.smallContentSpacing
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])

        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update() {
        emailLabel.text = linkAccount?.email
    }

    @objc func logoutTapped(_ sender: UIButton) {
        coordinator?.logout()
    }

}
