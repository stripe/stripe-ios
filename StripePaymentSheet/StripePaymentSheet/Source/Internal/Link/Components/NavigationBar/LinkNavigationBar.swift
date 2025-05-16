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
class LinkSheetNavigationBar: SheetNavigationBar {
    private let logoView: UIImageView = {
        let imageView = UIImageView(image: Image.link_logo.makeImage(template: false))
        imageView.tintColor = .linkNavLogo
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
            logoView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
