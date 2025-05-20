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

    private let logoView: UIImageView = {
        let imageView = UIImageView(image: Image.link_logo.makeImage(template: false))
        imageView.tintColor = .linkIconBrand
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

        tintColor = .linkIconSecondary
        backgroundColor = .linkSurfacePrimary

        addSubview(logoView)
        addSubview(backButton)
        addSubview(closeButton)

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
        // Back and close button are mutually exclusive.
        backButton.isHidden = !showBackButton
        closeButton.isHidden = showBackButton

        // Hide the logo if showing the back button.
        logoView.isHidden = showBackButton
    }
}
