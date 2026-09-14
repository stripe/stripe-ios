//
//  LinkVerificationView-Header.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 12/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension LinkVerificationView {

    final class Header: UIView {
        struct Constants {
            static let logoHeight: CGFloat = 24
        }

        private let brand: LinkBrand
        private let buttonSize = LinkUI.navigationBarButtonSize

        private lazy var logoView: UIImageView = {
            let logoView = UIImageView(image: brand.paymentSheetLogoImage)
            logoView.translatesAutoresizingMaskIntoConstraints = false
            logoView.isAccessibilityElement = true
            logoView.accessibilityTraits = .header
            logoView.accessibilityLabel = brand.accessibilityDisplayName
            return logoView
        }()

        let closeButton: UIButton = {
            LinkSheetNavigationBar.createCloseButton(
                accessibilityIdentifier: "LinkVerificationCloseButton",
                appearance: LinkUI.appearance
            )
        }()

        let backButton: UIButton = {
            let button = LinkSheetNavigationBar.createBackButton(
                accessibilityIdentifier: "LinkVerificationBackButton",
                appearance: LinkUI.appearance
            )
            button.isHidden = true
            return button
        }()

        var showsBackButton = false {
            didSet {
                backButton.isHidden = !showsBackButton
                logoView.isHidden = showsBackButton
            }
        }

        override var intrinsicContentSize: CGSize {
            return CGSize(width: 72, height: buttonSize)
        }

        init(brand: LinkBrand = .link) {
            self.brand = brand
            super.init(frame: .zero)

            addSubview(logoView)
            addSubview(closeButton)
            addSubview(backButton)

            NSLayoutConstraint.activate([
                // Logo
                logoView.leadingAnchor.constraint(equalTo: leadingAnchor),
                logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
                logoView.heightAnchor.constraint(equalToConstant: Constants.logoHeight),

                // Button
                closeButton.topAnchor.constraint(equalTo: topAnchor),
                closeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
                closeButton.bottomAnchor.constraint(equalTo: bottomAnchor),
                closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor),
                backButton.leadingAnchor.constraint(equalTo: leadingAnchor),
                backButton.topAnchor.constraint(equalTo: topAnchor),
                backButton.bottomAnchor.constraint(equalTo: bottomAnchor),
                backButton.widthAnchor.constraint(equalTo: backButton.heightAnchor),
            ])

            tintColor = .linkSurfacePrimary
            logoView.tintColor = .linkTextPrimary
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

}
