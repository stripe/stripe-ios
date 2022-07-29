//
//  LinkVerificationView-Header.swift
//  StripeiOS
//
//  Created by Ramon Torres on 12/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension LinkVerificationView {

    final class Header: UIView {
        struct Constants {
            static let logoHeight: CGFloat = 18
        }

        private let logoView: UIImageView = {
            let logoView = UIImageView(image: Image.link_logo.makeImage(template: true))
            logoView.translatesAutoresizingMaskIntoConstraints = false
            logoView.isAccessibilityElement = true  
            logoView.accessibilityTraits = .header
            logoView.accessibilityLabel = STPPaymentMethodType.link.displayName
            return logoView
        }()

        let closeButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(Image.icon_cancel.makeImage(template: true), for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.accessibilityLabel = String.Localized.close
            return button
        }()

        override var intrinsicContentSize: CGSize {
            return CGSize(width: UIView.noIntrinsicMetric, height: 24)
        }

        init() {
            super.init(frame: .zero)

            addSubview(logoView)
            addSubview(closeButton)

            NSLayoutConstraint.activate([
                // Logo
                logoView.centerXAnchor.constraint(equalTo: centerXAnchor),
                logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
                logoView.heightAnchor.constraint(equalToConstant: Constants.logoHeight),

                // Button
                closeButton.topAnchor.constraint(equalTo: topAnchor),
                closeButton.rightAnchor.constraint(equalTo: rightAnchor),
                closeButton.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

            tintColor = .linkNavTint
            logoView.tintColor = .linkNavLogo
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

}
