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
        self.view.backgroundColor = .white

        var appearance = PaymentSheet.Appearance.default
        appearance.paymentOptionView.style = .flatRadio

        let paymentMethodsView = EmbeddedPaymentMethodsView(savedPaymentMethod: nil, appearance: appearance, shouldShowApplePay: true, shouldShowLink: true)
        paymentMethodsView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(paymentMethodsView)

        NSLayoutConstraint.activate([
            paymentMethodsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            paymentMethodsView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            paymentMethodsView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
        ])
    }
}
