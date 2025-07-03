//
//  LinkPaymentMethodPicker-CellContentView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension LinkShippingAddressListView {

    final class CellContentView: UIView {
        struct Constants {
            static let contentSpacing: CGFloat = 12
            static let iconSize: CGSize = CardBrandView.targetIconSize
            static let maxFontSize: CGFloat = 20
        }

        var shippingAddress: ShippingAddressesResponse.ShippingAddress? {
            didSet {
                if let name = shippingAddress?.address.name {
                    primaryLabel.isHidden = false
                    primaryLabel.text = name
                } else {
                    primaryLabel.isHidden = true
                }
                secondaryLabel.text = shippingAddress?.address.description ?? ""
                secondaryLabel.numberOfLines = 0
            }
        }

        private let primaryLabel: UILabel = {
            let label = UILabel()
            label.adjustsFontForContentSizeCategory = true
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized, maximumPointSize: Constants.maxFontSize)
            label.textColor = .linkTextPrimary
            return label
        }()

        private let secondaryLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .caption, maximumPointSize: Constants.maxFontSize)
            label.textColor = .linkTextTertiary
            return label
        }()

        private lazy var stackView: UIStackView = {
            let labelStackView = UIStackView(arrangedSubviews: [
                primaryLabel,
                secondaryLabel,
            ])
            labelStackView.axis = .vertical
            labelStackView.alignment = .leading
            labelStackView.spacing = 0

            return labelStackView
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addAndPinSubview(stackView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

}
