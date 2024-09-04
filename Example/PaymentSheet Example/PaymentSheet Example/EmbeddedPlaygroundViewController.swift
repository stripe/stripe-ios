//
//  EmbeddedPlaygroundViewController.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 9/4/24.
//

import Foundation
@_spi(STP) import StripePaymentSheet
import UIKit

class EmbeddedPlaygroundViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .secondarySystemBackground
            }

            return .systemBackground
        })

        var appearance = PaymentSheet.Appearance.default
        appearance.paymentOptionView.style = .flatRadio

        let amex =
            [
                "card": [
                    "id": "preloaded_amex",
                    "exp_month": "10",
                    "exp_year": "2020",
                    "last4": "0005",
                    "brand": "amex",
                ],
                "type": "card",
                "id": "preloaded_amex",
            ] as [String: Any]
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: amex)

        let paymentMethodsView = EmbeddedPaymentMethodsView(savedPaymentMethod: paymentMethod, appearance: appearance, shouldShowApplePay: true, shouldShowLink: true)
        paymentMethodsView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(paymentMethodsView)

        NSLayoutConstraint.activate([
            paymentMethodsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            paymentMethodsView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            paymentMethodsView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
        ])
    }
}
