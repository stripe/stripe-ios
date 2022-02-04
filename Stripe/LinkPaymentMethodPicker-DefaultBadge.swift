//
//  LinkPaymentMethodPicker-DefaultBadge.swift
//  StripeiOS
//
//  Created by Ramon Torres on 10/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

extension LinkPaymentMethodPicker {

    final class DefaultBadge: UIView {

        private let textLabel: UILabel = {
            let label = UILabel()
            // TODO(ramont): Localize
            label.text = "Default"
            label.textAlignment = .center
            label.font = LinkUI.font(forTextStyle: .captionEmphasized, maximumPointSize: 16)
            label.adjustsFontForContentSizeCategory = true
            label.translatesAutoresizingMaskIntoConstraints = false
            label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            addAndPinSubview(textLabel, insets: .insets(top: 4, leading: 4, bottom: 4, trailing: 4))

            backgroundColor = .linkBadgeBackground
            textLabel.textColor = .linkBadgeForeground

            layer.cornerRadius = 4
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }

}
