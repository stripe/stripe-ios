//
//  USBankAccountExampleViewController.swift
//  Non-Card Payment Examples
//
//  Created by Cameron Sabol on 3/2/22.
//  Copyright © 2022 Stripe. All rights reserved.
//

import UIKit

class USBankAccountExampleViewController: UIViewController {
    @objc weak var delegate: ExampleViewControllerDelegate?
    var inProgress: Bool = false {
        didSet {
            navigationController?.navigationBar.isUserInteractionEnabled = !inProgress
            payButton.isEnabled = !inProgress
            inProgress
                ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
            fieldsStackView.isUserInteractionEnabled = !inProgress
        }
    }

    // UI
    lazy var nameField: UITextField = {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.borderStyle = .roundedRect
        textField.placeholder = "Name"
        return textField
    }()
    lazy var emailField: UITextField = {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.borderStyle = .roundedRect
        textField.placeholder = "Email"
        return textField
    }()
    lazy var accountNumberField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Account number"
        textField.keyboardType = .numberPad
        return textField
    }()
    lazy var routingNumberField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Routing number"
        textField.keyboardType = .numberPad
        return textField
    }()
    lazy var accountTypeSelector: UISegmentedControl = UISegmentedControl(items: ["checking", "savings"])
    lazy var accountHolderTypeSelector: UISegmentedControl = UISegmentedControl(items: ["individual", "company"])
    lazy var fieldsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameField,
                                                       emailField,
                                                       accountNumberField,
                                                       routingNumberField,
                                                       accountTypeSelector,
                                                       accountHolderTypeSelector])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 4
        return stackView
    }()
    lazy var activityIndicatorView = {
        return UIActivityIndicatorView(style: .gray)
    }()
    lazy var payButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Pay with US Bank Account", for: .normal)
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "US Bank Account"
        [payButton, activityIndicatorView].forEach { subview in
            view.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false
        }
        fieldsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fieldsStackView)
        
        let mandateLabel = UILabel()
        mandateLabel.numberOfLines = 0
        mandateLabel.font = .preferredFont(forTextStyle: .caption1)
        mandateLabel.text = """
        By clicking Pay with US Bank Account, you authorize Non-Card Payment Examples to debit the bank account specified above for any amount owed for charges arising from your use of Non-Card Payment Examples’ services and/or purchase of products from Non-Card Payment Examples, pursuant to Non-Card Payment Examples’ website and terms, until this authorization is revoked. You may amend or cancel this authorization at any time by providing notice to Non-Card Payment Examples with 30 (thirty) days notice.
        
        If you use Non-Card Payment Examples’ services or purchase additional products periodically pursuant to Non-Card Payment Examples’ terms, you authorize Non-Card Payment Examples to debit your bank account periodically. Payments that fall outside of the regular debits authorized above will only be debited after your authorization is obtained.
"""
        mandateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mandateLabel)

        let constraints = [
            fieldsStackView.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1),
            fieldsStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: fieldsStackView.trailingAnchor, multiplier: 1),
            
            nameField.widthAnchor.constraint(equalTo: fieldsStackView.widthAnchor),
            emailField.widthAnchor.constraint(equalTo: fieldsStackView.widthAnchor),
            accountNumberField.widthAnchor.constraint(equalTo: fieldsStackView.widthAnchor),
            routingNumberField.widthAnchor.constraint(equalTo: fieldsStackView.widthAnchor),
            
            mandateLabel.topAnchor.constraint(equalToSystemSpacingBelow: fieldsStackView.bottomAnchor, multiplier: 1),
            mandateLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: mandateLabel.trailingAnchor, multiplier: 1),

            
            payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            payButton.topAnchor.constraint(equalToSystemSpacingBelow: mandateLabel.bottomAnchor, multiplier: 1),

            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: payButton.centerYAnchor),
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

extension USBankAccountExampleViewController {
    @objc func pay() {
        // 1. Create a US Bank Account PaymentIntent
        MyAPIClient.shared().createPaymentIntent(
            completion: { [self] (result, clientSecret, error) in
                guard let clientSecret = clientSecret else {
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
                    return
                }
                // 2. Collect payment method params information
                let usBankAccountParams = STPPaymentMethodUSBankAccountParams()
                usBankAccountParams.accountType = accountTypeSelector.titleForSegment(at: max(accountTypeSelector.selectedSegmentIndex, 0)) == "checking" ? .checking : .savings
                usBankAccountParams.accountHolderType = accountHolderTypeSelector.titleForSegment(at: max(accountHolderTypeSelector.selectedSegmentIndex, 0)) == "individual" ? .individual : .company
                usBankAccountParams.accountNumber = accountNumberField.text
                usBankAccountParams.routingNumber = routingNumberField.text
                
                let billingDetails = STPPaymentMethodBillingDetails()
                billingDetails.name = nameField.text
                billingDetails.email = emailField.text
                
                let paymentMethodParams = STPPaymentMethodParams(usBankAccount: usBankAccountParams,
                                                                 billingDetails: billingDetails,
                                                                 metadata: nil)
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodParams = paymentMethodParams
                paymentIntentParams.returnURL = "payments-example://stripe/"
                
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
                            self, didFinishWithMessage: "Payment successfully initiated. Will fulfill after microdeposit verification")
                    @unknown default:
                        fatalError()
                    }
                }
            }, additionalParameters: "supported_payment_methods=us_bank_account")
    }
}

extension USBankAccountExampleViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        self
    }
}
