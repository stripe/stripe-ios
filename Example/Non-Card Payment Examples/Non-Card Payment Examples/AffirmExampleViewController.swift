//
//  AffirmExampleViewController.swift
//  Non-Card Payment Examples
//
//  Copyright © 2022 Stripe. All rights reserved.
//

import Stripe
import UIKit

class AffirmExampleViewController: UIViewController {
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
        button.setTitle("Pay with Affirm", for: .normal)
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Affirm"
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
                self, didFinishWithMessage: "Please set a Stripe Publishable Key in Constants.m")
            return
        }
        inProgress = true
        pay()
    }
}

// MARK: -
extension AffirmExampleViewController {
    @objc func pay() {
        // 1. Create an Affirm PaymentIntent
        MyAPIClient.shared().createPaymentIntent(
            completion: { (result, clientSecret, error) in
                guard let clientSecret = clientSecret else {
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
                    return
                }
                // 2. Collect shipping information
                let shippingAddress = STPPaymentIntentShippingDetailsAddressParams(line1: "55 John St")
                shippingAddress.line2 = "#3B"
                shippingAddress.city = "New York"
                shippingAddress.state = "NY"
                shippingAddress.postalCode = "10002"
                shippingAddress.country = "US"

                let shippingDetailsParam = STPPaymentIntentShippingDetailsParams(address: shippingAddress,
                                                                                 name: "TestName")
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
                    affirm: STPPaymentMethodAffirmParams(),
                    metadata: [:])
                paymentIntentParams.returnURL = "payments-example://safepay/"
                paymentIntentParams.shipping = shippingDetailsParam
                
                // 3. Confirm payment
                STPPaymentHandler.shared().confirmPayment(
                    paymentIntentParams, with: self
                ) { (status, intent, error) in
                    switch status {
                    case .canceled:
                        self.delegate?.exampleViewController(
                            self, didFinishWithMessage: "Cancelled")
                    case .failed:
                        self.delegate?.exampleViewController(self, didFinishWithError: error)
                    case .succeeded:
                        self.delegate?.exampleViewController(
                            self, didFinishWithMessage: "Payment successfully created.")
                    @unknown default:
                        fatalError()
                    }
                }
            }, additionalParameters: "supported_payment_methods=affirm&products[]=👛")
    }
}

extension AffirmExampleViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        self
    }
}
