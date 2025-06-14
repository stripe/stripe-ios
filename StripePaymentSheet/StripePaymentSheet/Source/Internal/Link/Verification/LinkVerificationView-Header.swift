//
//  LinkVerificationView-Header.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 12/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension LinkVerificationView {

    final class Header: UIView {
        struct Constants {
            static let logoHeight: CGFloat = 24
        }

        private let logoView: UIImageView = {
            let logoView = UIImageView(image: Image.link_logo.makeImage(template: false))
            logoView.translatesAutoresizingMaskIntoConstraints = false
            logoView.isAccessibilityElement = true
            logoView.accessibilityTraits = .header
            logoView.accessibilityLabel = STPPaymentMethodType.link.displayName
            return logoView
        }()

        let closeButton: UIButton = {
            LinkSheetNavigationBar.createCloseButton(
                accessibilityIdentifier: "LinkVerificationCloseButton",
                appearance: LinkUI.appearance
            )
        }()

        override var intrinsicContentSize: CGSize {
            return CGSize(width: 72, height: 32)
        }

        init() {
            super.init(frame: .zero)

            addSubview(logoView)
            addSubview(closeButton)

            NSLayoutConstraint.activate([
                // Logo
                logoView.leadingAnchor.constraint(equalTo: leadingAnchor),
                logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
                logoView.heightAnchor.constraint(equalToConstant: Constants.logoHeight),

                // Button
                closeButton.topAnchor.constraint(equalTo: topAnchor),
                closeButton.rightAnchor.constraint(equalTo: rightAnchor),
                closeButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

            tintColor = .linkSurfacePrimary
            logoView.tintColor = .linkTextPrimary
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

}
