//
//  CashAppExampleViewController.swift
//  Non-Card Payment Examples
//
//  Created by Nick Porter on 12/12/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import Stripe
import UIKit

class CashAppExampleViewController: UIViewController {
    @objc weak var delegate: ExampleViewControllerDelegate?
    var inProgress: Bool = false {
        didSet {
            navigationController?.navigationBar.isUserInteractionEnabled = !inProgress
            payButton.isEnabled = !inProgress
            inProgress
                ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
        }
    }

    // UI
    lazy var activityIndicatorView = {
        return UIActivityIndicatorView(style: .gray)
    }()
    lazy var payButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Pay with Cash App Pay", for: .normal)
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Cash App Pay"
        [payButton, activityIndicatorView].forEach { subview in
            view.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        let constraints = [
            payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            payButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc func didTapPayButton() {
        guard STPAPIClient.shared.publishableKey != nil else {
            delegate?.exampleViewController(
                self,
                didFinishWithMessage: "Please set a Stripe Publishable Key in Constants.m"
            )
            return
        }
        inProgress = true
        pay()
    }
}

// MARK: -
extension CashAppExampleViewController {
    @objc func pay() {
        // 1. Create an CashApp PaymentIntent
        MyAPIClient.shared().createPaymentIntent(
            completion: { (_, clientSecret, error) in
                guard let clientSecret = clientSecret else {
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
                    return
                }

                // 2. Confirm the payment and redirect the user to Cash App
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
                    cashApp: STPPaymentMethodCashAppParams(),
                    billingDetails: nil,
                    metadata: nil
                )
                paymentIntentParams.returnURL = "payments-example://safepay/"

                STPPaymentHandler.shared().confirmPayment(
                    paymentIntentParams,
                    with: self
                ) { (status, _, error) in
                    switch status {
                    case .canceled:
                        self.delegate?.exampleViewController(
                            self,
                            didFinishWithMessage: "Cancelled"
                        )
                    case .failed:
                        self.delegate?.exampleViewController(self, didFinishWithError: error)
                    case .succeeded:
                        self.delegate?.exampleViewController(
                            self,
                            didFinishWithMessage: "Payment successfully created."
                        )
                    @unknown default:
                        fatalError()
                    }
                }
            },
            additionalParameters: "supported_payment_methods=cashapp"
        )
    }
}

extension CashAppExampleViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        self
    }
}
