//
//  LinkSheetNavigationBar.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 3/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_LinkSheetNavigationBar)
class LinkSheetNavigationBar: SheetNavigationBar {
    override class var height: CGFloat {
        return 70
    }
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
        let button = SheetNavigationButton(type: .custom)

        // Create circular background
        button.backgroundColor = .linkSurfaceSecondary
        button.layer.cornerRadius = 15 // Half of the desired 30px diameter

        // Set up the image with 14px size
        let closeImage = Image.icon_chevron_left_standalone.makeImage(template: true)
        let resizedImage = closeImage.withConfiguration(
            closeImage.configuration?.applying(
                UIImage.SymbolConfiguration(pointSize: 14)
            ) ?? UIImage.SymbolConfiguration(pointSize: 14)
        )

        button.setImage(resizedImage, for: .normal)
        button.tintColor = appearance.colors.icon
        button.accessibilityLabel = String.Localized.back
        button.accessibilityIdentifier = "UIButton.Back"

        // Set fixed size for the button
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30),
        ])

        return button
    }

    override func createCloseButton() -> UIButton {
        let button = SheetNavigationButton(type: .custom)

        // Create circular background
        button.backgroundColor = .linkSurfaceSecondary
        button.layer.cornerRadius = 15 // Half of the desired 30px diameter

        // Set up the image with 14px size
        let closeImage = Image.icon_x_standalone.makeImage(template: true)
        let resizedImage = closeImage.withConfiguration(
            closeImage.configuration?.applying(
                UIImage.SymbolConfiguration(pointSize: 14)
            ) ?? UIImage.SymbolConfiguration(pointSize: 14)
        )

        button.setImage(resizedImage, for: .normal)
        button.tintColor = appearance.colors.icon
        button.accessibilityLabel = String.Localized.close
        button.accessibilityIdentifier = "UIButton.Close"

        // Set fixed size for the button
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30),
        ])

        return button
    }
}
