//
//  BacsDebitViewController.swift
//  Non-Card Payment Examples
//
//  Created by Yuki Tokuhiro on 2/18/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

import UIKit
import Stripe

/**
 An example of accepting Bacs Debit payments.
 
 There are some limitations:
 1. Your Stripe account's country must be UK
 2. The currency value of the PaymentIntent or SetupIntent must be GBP
 3. The UI to collect payment details is subject to strict requirements and must be approved by Stripe - contact bacs-debit@stripe.com
 */
class BacsDebitExampleViewController: UIViewController {
    @objc weak var delegate: ExampleViewControllerDelegate?
    var inProgress: Bool = false {
        didSet {
            navigationController?.navigationBar.isUserInteractionEnabled = !inProgress
            payButton.isEnabled = !inProgress
            inProgress ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
        }
    }

    // UI
    lazy var activityIndicatorView = {
       return UIActivityIndicatorView(style: .gray)
    }()
    lazy var payButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Pay with Bacs Debit", for: .normal)
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        return button
    }()
    lazy var setupButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Set up Bacs Debit for future payment", for: .normal)
        button.addTarget(self, action: #selector(didTapSetupButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Bacs Debit"
        [payButton, setupButton, activityIndicatorView].forEach { subview in
            view.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        let constraints = [
            payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            payButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            setupButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            setupButton.topAnchor.constraint(equalTo: payButton.bottomAnchor),

            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc func didTapPayButton(sender: UIButton) {
        inProgress = true

        /**
         You must provide UI to collect the following hard-coded customer information. Bacs in the UK has strict requirements around customer-facing mandate collection forms. Stripe needs to approve any forms for collecting mandates. Contact bacs-debits@stripe.com with any questions.
         */
        let bacsDebitParams = STPPaymentMethodBacsDebitParams()
        bacsDebitParams.accountNumber = "00012345"
        bacsDebitParams.sortCode = "108800"

        let address = STPPaymentMethodAddress()
        address.line1 = "29 Arlington Avenue"
        address.city = "London"
        address.postalCode = "N1 7BE"
        address.country = "GB"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Chiaki"
        billingDetails.email = "email@email.com"
        billingDetails.address = address

        let paymentMethodParams = STPPaymentMethodParams(bacsDebit: bacsDebitParams, billingDetails: billingDetails, metadata: nil)

        MyAPIClient.shared().createPaymentIntent(completion: { (_, clientSecret, error) in
            guard let clientSecret = clientSecret else {
                self.delegate?.exampleViewController(self, didFinishWithError: error)
                return
            }

            let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
            paymentIntentParams.paymentMethodParams = paymentMethodParams

            STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: self) { (_, _, error) in
                guard error == nil else {
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
                    return
                }
                self.delegate?.exampleViewController(self, didFinishWithMessage: "Your order was received and is awaiting payment confirmation.")
            }
        }, additionalParameters: nil)
    }

    @objc func didTapSetupButton() {
        inProgress = true

        /**
         You must provide UI to collect the following hard-coded customer information. Bacs in the UK has strict requirements around customer-facing mandate collection forms. Stripe needs to approve any forms for collecting mandates. Contact bacs-debits@stripe.com with any questions.
         */
        let bacsDebitParams = STPPaymentMethodBacsDebitParams()
        bacsDebitParams.accountNumber = "00012345"
        bacsDebitParams.sortCode = "108800"

        let address = STPPaymentMethodAddress()
        address.line1 = "29 Arlington Avenue"
        address.city = "London"
        address.postalCode = "N1 7BE"
        address.country = "GB"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Chiaki"
        billingDetails.email = "email@email.com"
        billingDetails.address = address

        let paymentMethodParams = STPPaymentMethodParams(bacsDebit: bacsDebitParams, billingDetails: billingDetails, metadata: nil)

        MyAPIClient.shared().createSetupIntent { (_, clientSecret, error) in
            guard let clientSecret = clientSecret else {
                self.delegate?.exampleViewController(self, didFinishWithError: error)
                return
            }

            let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: clientSecret)
            setupIntentParams.paymentMethodParams = paymentMethodParams
            STPPaymentHandler.shared().confirmSetupIntent(setupIntentParams, with: self) { (_, _, error) in
                guard error == nil else {
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
                    return
                }
                self.delegate?.exampleViewController(self, didFinishWithMessage: "Your order was received and is awaiting payment confirmation.")
            }
        }
    }
}

// MARK: -
extension BacsDebitExampleViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        self
    }
}
