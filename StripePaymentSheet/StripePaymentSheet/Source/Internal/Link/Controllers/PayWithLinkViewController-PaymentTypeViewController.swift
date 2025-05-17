//
//  PayWithLinkViewController-PaymentTypeViewController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 5/15/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_PaymentTypeViewController)
    final class PaymentTypeViewController: BaseViewController {

        private lazy var paymentTypePicker: LinkPaymentTypePicker = {
            let paymentTypePicker = LinkPaymentTypePicker()
            paymentTypePicker.translatesAutoresizingMaskIntoConstraints = false
            return paymentTypePicker
        }()

        override func viewDidLoad() {
            super.viewDidLoad()
            contentView.addSubview(paymentTypePicker)

            NSLayoutConstraint.activate([
                paymentTypePicker.topAnchor.constraint(equalTo: contentView.topAnchor),
                paymentTypePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                paymentTypePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            ])
        }
    }
}
