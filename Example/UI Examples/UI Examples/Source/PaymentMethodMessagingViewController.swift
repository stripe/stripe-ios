//
//  PaymentMethodMessagingViewController.swift
//  UI Examples
//
//  Created by Yuki Tokuhiro on 9/28/22.
//  Copyright © 2022 Stripe. All rights reserved.
//

//  🏗 Under construction
//  Note: Do not import Stripe using `@_spi(STP)` or @testable in production.
//  This exposes internal functionality which may cause unexpected behavior if used directly.
@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePaymentsUI
import UIKit

class PaymentMethodMessagingViewController: UIViewController {
    var theme = STPTheme.defaultTheme

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PaymentMethodMessagingView Demo"
        view.backgroundColor = .systemBackground
        let config = PaymentMethodMessagingView.Configuration(
            paymentMethods: [.afterpayClearpay, .klarna],
            currency: "USD",
            amount: 2499
        )
        PaymentMethodMessagingView.create(configuration: config) { [weak self] result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let paymentMethodMessagingView):
                paymentMethodMessagingView.adjustsFontForContentSizeCategory = true
                // Add a border
                paymentMethodMessagingView.layer.borderWidth = 0.5
                paymentMethodMessagingView.layer.borderColor = UIColor.lightGray.cgColor
                paymentMethodMessagingView.layer.cornerRadius = 5

                self?.addPaymentMethodMessagingView(paymentMethodMessagingView)
            }
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
    }

    @objc func done() {
        dismiss(animated: true, completion: nil)
    }

    private func addPaymentMethodMessagingView(_ paymentMethodMessagingView: PaymentMethodMessagingView) {
        view.addSubview(paymentMethodMessagingView)
        paymentMethodMessagingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            paymentMethodMessagingView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            paymentMethodMessagingView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            paymentMethodMessagingView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])
    }
}
