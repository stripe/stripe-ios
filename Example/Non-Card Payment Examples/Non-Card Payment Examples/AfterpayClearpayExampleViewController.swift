//
//  AfterpayClearpayExampleViewController.swift
//  Non-Card Payment Examples
//
//  Created by Ali Riaz on 1/14/21.
//  Copyright © 2021 Stripe. All rights reserved.
//

import Stripe
import UIKit

class AfterpayClearpayExampleViewController: UIViewController {
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
        button.setTitle("Pay with Afterpay Clearpay", for: .normal)
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Afterpay Clearpay"
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
extension AfterpayClearpayExampleViewController {
    @objc func pay() {
        // 1. Create an Afterpay Clearpay PaymentIntent
        MyAPIClient.shared().createPaymentIntent(
            completion: { (_, clientSecret, error) in
                guard let clientSecret = clientSecret else {
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
                    return
                }

                // 2. Collect billing & shipping details
                let billingDetails = STPPaymentMethodBillingDetails()
                billingDetails.name = "Jane Doe"
                billingDetails.email = "email@email.com"
                let billingAddress = STPPaymentMethodAddress()
                billingAddress.line1 = "510 Townsend St."
                billingAddress.postalCode = "94102"
                billingAddress.country = "US"
                billingDetails.address = billingAddress

                let shippingAddress = STPPaymentIntentShippingDetailsAddressParams(
                    line1: "510 Townsend St.")
                shippingAddress.country = "US"
                shippingAddress.postalCode = "94102"
                let shippingDetails = STPPaymentIntentShippingDetailsParams(
                    address: shippingAddress, name: "Jane Doe")

                // 2. Confirm the payment and redirect the user to Afterpay
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
                    afterpayClearpay: STPPaymentMethodAfterpayClearpayParams(),
                    billingDetails: billingDetails,
                    metadata: nil)
                paymentIntentParams.returnURL = "payments-example://safepay/"
                paymentIntentParams.shipping = shippingDetails

                STPPaymentHandler.shared().confirmPayment(
                    withParams: paymentIntentParams, authenticationContext: self
                ) { (status, _, error) in
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
            }, additionalParameters: "supported_payment_methods=card,afterpay_clearpay")
    }
}

extension AfterpayClearpayExampleViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        self
    }
}
