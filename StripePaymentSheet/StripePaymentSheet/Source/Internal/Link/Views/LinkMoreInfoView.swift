//
//  LinkMoreInfoView.swift
//  StripePaymentSheet
//
//  Created by Bill Meltsner on 6/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// For internal SDK use only
@objc(STP_Internal_LinkMoreInfoView)
final class LinkMoreInfoView: UIView {
    struct Constants {
        static var logoWidth: CGFloat = 42
        static let logoHeight: CGFloat = 14
    }
    private lazy var logoView: UIImageView = {
        let imageView: UIImageView
        imageView = DynamicImageView(dynamicImage: Image.link_logo_knockout.makeImage(template: false), pairedColor: theme.colors.background)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = STPPaymentMethodType.link.displayName
        return imageView
    }()

    private let theme: ElementsUITheme

    init(theme: ElementsUITheme = .default) {
        self.theme = theme
        super.init(frame: .zero)
        addSubview(logoView)
        let widthConstraint = logoView.widthAnchor.constraint(equalToConstant: Constants.logoWidth)
        widthConstraint.priority = .required
        let heightConstraint = logoView.heightAnchor.constraint(equalToConstant: Constants.logoHeight)
        heightConstraint.priority = .required
        let leadingConstraint = logoView.leadingAnchor.constraint(equalTo: leadingAnchor)
        leadingConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            logoView.topAnchor.constraint(equalTo: topAnchor),
            logoView.bottomAnchor.constraint(equalTo: bottomAnchor),
            logoView.trailingAnchor.constraint(equalTo: trailingAnchor),
            leadingConstraint,
            widthConstraint,
            heightConstraint,
        ])
    }

    override var intrinsicContentSize: CGSize {
        .init(width: Constants.logoWidth, height: Constants.logoHeight)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
