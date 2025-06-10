//
//  LinkSheetNavigationBar.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 3/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_LinkSheetNavigationBar)
class LinkSheetNavigationBar: SheetNavigationBar {
    private let logoView: UIImageView = {
        let imageView = UIImageView(image: Image.link_logo.makeImage(template: false))
        imageView.tintColor = .linkIconBrand
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = .header
        imageView.accessibilityLabel = STPPaymentMethodType.link.displayName
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(isTestMode: Bool, appearance: PaymentSheet.Appearance) {
        super.init(isTestMode: isTestMode, appearance: appearance)

        logoView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoView)

        NSLayoutConstraint.activate([
            logoView.leftAnchor.constraint(equalTo: leftAnchor, constant: LinkUI.contentMargins.leading),
            logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: LinkUI.navigationBarHeight)
    }

    override func setStyle(_ style: SheetNavigationBar.Style) {
        super.setStyle(style)
        if case .back = style {
            logoView.isHidden = true
        } else {
            logoView.isHidden = false
        }
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func createBackButton() -> UIButton {
        return Self.createButton(
            with: Image.icon_chevron_left_standalone.makeImage(template: true),
            accessibilityLabel: String.Localized.back,
            accessibilityIdentifier: "UIButton.Back",
            appearance: appearance
        )
    }

    override func createCloseButton() -> UIButton {
        return Self.createButton(
            with: Image.icon_x_standalone.makeImage(template: true),
            accessibilityLabel: String.Localized.close,
            accessibilityIdentifier: "UIButton.Close",
            appearance: appearance
        )
    }

    static func createButton(
        with image: UIImage,
        accessibilityLabel: String,
        accessibilityIdentifier: String,
        appearance: PaymentSheet.Appearance
    ) -> UIButton {
        let button = SheetNavigationButton(type: .custom)

        // Create circular background
        button.backgroundColor = .linkSurfaceSecondary
        button.layer.cornerRadius = 16 // Half of the desired 32px diameter

        // Set up the image with 12px size
        let resizedImage = image.withConfiguration(
            image.configuration?.applying(
                UIImage.SymbolConfiguration(pointSize: 12)
            ) ?? UIImage.SymbolConfiguration(pointSize: 12)
        )

        button.setImage(resizedImage, for: .normal)
        button.tintColor = appearance.colors.icon
        button.contentMode = .scaleAspectFit
        button.accessibilityLabel = accessibilityLabel
        button.accessibilityIdentifier = accessibilityIdentifier

        // Set fixed size for the button
        button.translatesAutoresizingMaskIntoConstraints = false

        // Constrain the button size
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32),
        ])

        // Constrain the image view size
        if let imageView = button.imageView {
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 12),
                imageView.heightAnchor.constraint(equalToConstant: 12),
                imageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            ])
        }

        return button
    }
}
