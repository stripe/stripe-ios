//
//  KlarnaExampleViewController.swift
//  Custom Integration
//
//  Created by David Estes on 10/28/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit
import Stripe

class KlarnaExampleViewController: UIViewController {
    @objc weak var delegate: ExampleViewControllerDelegate?
    var redirectContext: STPRedirectContext?
    var inProgress: Bool = false {
        didSet {
            navigationController?.navigationBar.isUserInteractionEnabled = !inProgress
            payWithAddressButton.isEnabled = !inProgress
            payWithoutAddressButton.isEnabled = !inProgress
            inProgress ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
        }
    }

    // UI
    lazy var activityIndicatorView = {
       return UIActivityIndicatorView(style: .gray)
    }()
    lazy var payWithoutAddressButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Pay with Klarna (Unknown Customer Address)", for: .normal)
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        return button
    }()
    lazy var payWithAddressButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Pay with Klarna (Known Customer Address)", for: .normal)
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Klarna"
        [payWithAddressButton, payWithoutAddressButton, activityIndicatorView].forEach { subview in
            view.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        let constraints = [
            payWithAddressButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            payWithAddressButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            payWithoutAddressButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            payWithoutAddressButton.topAnchor.constraint(equalTo: payWithAddressButton.bottomAnchor),

            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc func didTapPayButton(sender: UIButton) {
        guard StripeAPI.defaultPublishableKey != nil else {
            delegate?.exampleViewController(self, didFinishWithMessage: "Please set a Stripe Publishable Key in Constants.m")
            return
        }
        inProgress = true
        if sender == payWithAddressButton {
            payWithKnownCustomerInfo()
        } else {
            payWithoutCustomerInfo()
        }
    }
}

// MARK: -
extension KlarnaExampleViewController {

    @objc func payWithKnownCustomerInfo() {
        // You can optionally pass the customer's information to Klarna. If this information is not
        // provided, Klarna will request it from the customer during checkout.
        // Note: If you do not provide all required fields (full street address, first/last names, and
        // email address), Stripe will not forward any address information to Klarna.

        let address = STPAddress()
        address.line1 = "29 Arlington Avenue"
        address.email = "test@example.com"
        address.city = "London"
        address.postalCode = "N1 7BE"
        address.country = "UK"
        address.phone = "02012267709"
        // Klarna requires separate first and last names for the customer.
        let firstName = "Arthur"
        let lastName = "Dent"

        // In some EU countries, Klarna uses the user's date of birth for a credit check.
        let dob = STPDateOfBirth.init()
        dob.day = 11
        dob.month = 3
        dob.year = 1952

        // Klarna requires individual line items in the transaction to be broken out
        let items = [STPKlarnaLineItem(itemType: .SKU, itemDescription: "Towel", quantity: 1, totalAmount: 10000),
                     STPKlarnaLineItem(itemType: .SKU, itemDescription: "Digital Watch", quantity: 2, totalAmount: 20000),
                     STPKlarnaLineItem(itemType: .tax, itemDescription: "Taxes", quantity: 1, totalAmount: 100),
                     STPKlarnaLineItem(itemType: .shipping, itemDescription: "Shipping", quantity: 1, totalAmount: 100)]

        let sourceParams = STPSourceParams.klarnaParams(
            withReturnURL: "payments-example://stripe-redirect",
            currency: "GBP",
            purchaseCountry: "UK",
            items: items,
            customPaymentMethods: [], // The CustomPaymentMethods flag is ignored outside the US
            billingAddress: address,
            billingFirstName: firstName,
            billingLastName: lastName,
            billingDOB: dob)

        // Klarna provides a wide variety of additional configuration options which you can use
        // via the `additionalAPIParameters` field. See https://stripe.com/docs/sources/klarna for details.
        if var additionalKlarnaParameters = sourceParams.additionalAPIParameters["klarna"] as? [String: Any] {
            additionalKlarnaParameters["page_title"] = "Zoo"
            sourceParams.additionalAPIParameters["klarna"] = additionalKlarnaParameters
        }

        payWithSourceParams(sourceParams: sourceParams)
    }

    @objc func payWithoutCustomerInfo() {
        // This is the minimal amount of information required for a Klarna transaction.
        // Klarna will request additional information from the customer during checkout.
        let items = [STPKlarnaLineItem(itemType: .SKU, itemDescription: "Mysterious Item", quantity: 1, totalAmount: 10000)]

        let sourceParams = STPSourceParams.klarnaParams(
            withReturnURL: "payments-example://stripe-redirect",
            currency: "USD",
            purchaseCountry: "US",
            items: items,
            customPaymentMethods: [.installments, .payIn4])

        payWithSourceParams(sourceParams: sourceParams)
    }

    @objc func payWithSourceParams(sourceParams: STPSourceParams) {
        // 1. Create an Klarna Source.
        STPAPIClient.shared.createSource(with: sourceParams) { source, error in
            guard let source = source else {
                self.delegate?.exampleViewController(self, didFinishWithError: error)
                return
            }
            // 2. Redirect your customer to Klarna.
            self.redirectContext = STPRedirectContext(source: source) { _, _, error in
                guard error == nil else {
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
                    return
                }

                // 3. Poll your backend to show the customer their order status.
                // This step is ommitted in the example, as our backend does not track orders.
                self.delegate?.exampleViewController(self, didFinishWithMessage: "Your order was received and is awaiting payment confirmation.")

                // 4. On your backend, use webhooks to charge the Source and fulfill the order
            }
            self.redirectContext?.startRedirectFlow(from: self)
        }
    }
}
