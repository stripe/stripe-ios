//
//  LinkNavigationBar.swift
//  StripeiOS
//
//  Created by Ramon Torres on 3/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_LinkNavigationBar)
final class LinkNavigationBar: UIView {
    struct Constants {
        static let buttonSize: CGSize = .init(width: 60, height: 44)
        static let margins: NSDirectionalEdgeInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
        static let maxFontSize: CGFloat = 18
        static let logoVerticalOffset: CGFloat = 14
        static let defaultHeight: CGFloat = 44
        static let heightWithLabel: CGFloat = 66
    }

    var linkAccount: PaymentSheetLinkAccountInfoProtocol? {
        didSet {
            emailLabel.text = linkAccount?.email
            showEmailLabel = linkAccount?.isRegistered ?? false
        }
    }

    var showBackButton: Bool = false {
        didSet {
            backButton.isHidden = !showBackButton
        }
    }

    private var showEmailLabel: Bool = false {
        didSet {
            emailLabel.isHidden = !showEmailLabel
            invalidateIntrinsicContentSize()
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
        let imageView = UIImageView(image: Image.link_logo.makeImage(template: true))
        imageView.tintColor = .linkNavLogo
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = .header
        imageView.accessibilityLabel = STPPaymentMethodType.link.displayName
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = LinkUI.font(forTextStyle: .body, maximumPointSize: Constants.maxFontSize)
        label.textColor = CompatibleColor.secondaryLabel
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingMiddle
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    override var intrinsicContentSize: CGSize {
        let baseHeight: CGFloat = showEmailLabel
            ? Constants.heightWithLabel
            : Constants.defaultHeight
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: baseHeight + safeAreaInsets.top + safeAreaInsets.bottom
        )
    }

    init() {
        super.init(frame: .zero)

        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentHuggingPriority(.defaultLow, for: .horizontal)

        tintColor = .linkNavTint
        backgroundColor = .linkBackground

        addSubview(logoView)
        addSubview(emailLabel)
        addSubview(backButton)
        addSubview(closeButton)

        insetsLayoutMarginsFromSafeArea = true
        directionalLayoutMargins = Constants.margins

        NSLayoutConstraint.activate([
            // Back button
            backButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            backButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize.width),
            backButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize.height),
            // Logo
            logoView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: Constants.logoVerticalOffset),
            logoView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
            logoView.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor),
            // Email label
            emailLabel.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
            emailLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            emailLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            // Close button
            closeButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize.height)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        invalidateIntrinsicContentSize()
    }
}
