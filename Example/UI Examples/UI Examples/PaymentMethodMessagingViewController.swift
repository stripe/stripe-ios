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
    lazy var containerView: UIView = {
        // Inset the payment method messaging view inside a bordered container
        let containerView = UIView()
        containerView.layer.borderWidth = 0.5
        containerView.layer.borderColor = UIColor.lightGray.cgColor
        containerView.layer.cornerRadius = 5
        return containerView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PaymentMethodMessagingView Demo"
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        // Add container view
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            containerView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
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
                self?.addPaymentMethodMessagingView(paymentMethodMessagingView)
            }
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationController?.navigationBar.stp_theme = theme
    }

    @objc func done() {
        dismiss(animated: true, completion: nil)
    }
    
    private func addPaymentMethodMessagingView(_ paymentMethodMessagingView: PaymentMethodMessagingView) {
        containerView.addSubview(paymentMethodMessagingView)
        paymentMethodMessagingView.translatesAutoresizingMaskIntoConstraints = false
        let inset = 8.0
        NSLayoutConstraint.activate([
            paymentMethodMessagingView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: inset),
            paymentMethodMessagingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -inset),
            paymentMethodMessagingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: inset),
            paymentMethodMessagingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -inset),
        ])
    }
}
