//
//  LinkNavigationBar.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 3/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_LinkNavigationBar)
final class LinkNavigationBar: UIView {
    struct Constants {
        static let buttonSize: CGSize = .init(width: 60, height: 44)
        static let logoSize: CGSize = .init(width: 72, height: 24)
        static let logoVerticalOffset: CGFloat = 14
        static let defaultHeight: CGFloat = 44
    }

    var linkAccount: PaymentSheetLinkAccountInfoProtocol? {
        didSet {
            update()
        }
    }

    var showBackButton: Bool = false {
        didSet {
            if showBackButton != oldValue {
                update()
            }
        }
    }

    let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Image.back_button.makeImage(), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = String.Localized.back
        button.isHidden = true
        return button
    }()

    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Image.icon_cancel.makeImage(), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = String.Localized.close
        return button
    }()

    let menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Image.icon_menu_horizontal.makeImage(), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = String.Localized.show_menu
        return button
    }()

    private let logoView: UIImageView = {
        let imageView = UIImageView(image: Image.link_logo.makeImage(template: false))
        imageView.tintColor = .linkNavLogo
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = .header
        imageView.accessibilityLabel = STPPaymentMethodType.link.displayName
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: Constants.defaultHeight + safeAreaInsets.top + safeAreaInsets.bottom
        )
    }

    init() {
        super.init(frame: .zero)

        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentHuggingPriority(.defaultLow, for: .horizontal)

        tintColor = .linkNavTint
        backgroundColor = .linkBackground

        addSubview(logoView)
        addSubview(backButton)
        addSubview(closeButton)
        addSubview(menuButton)

        NSLayoutConstraint.activate([
            // Back button
            backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            backButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            backButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            backButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize.width),
            backButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize.height),
            backButton.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),
            // Close button
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            closeButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            closeButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize.height),
            closeButton.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),
            // Logo
            logoView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Constants.logoVerticalOffset),
            logoView.heightAnchor.constraint(equalToConstant: Constants.logoSize.height),
            logoView.widthAnchor.constraint(equalToConstant: Constants.logoSize.width),
            logoView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            logoView.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor),
            // Menu button
            menuButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            menuButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            menuButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize.width),
            menuButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize.height),
            menuButton.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),
        ])

        update()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        invalidateIntrinsicContentSize()
    }

    private func update() {
        let isLoggedIn = linkAccount?.isLoggedIn ?? false

        // Back and close button are mutually exclusive.
        backButton.isHidden = !showBackButton
        closeButton.isHidden = showBackButton

        // Hide the logo if showing the back button.
        logoView.isHidden = showBackButton

        // Menu should be hidden if not logged in or we are currently showing the back button.
        menuButton.isHidden = !isLoggedIn || showBackButton
    }
}
