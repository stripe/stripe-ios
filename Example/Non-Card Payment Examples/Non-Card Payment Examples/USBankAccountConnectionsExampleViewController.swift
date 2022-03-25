//
//  USBankAccountConnectionsExampleViewController.swift
//  Non-Card Payment Examples
//
//  Created by Cameron Sabol on 3/23/22.
//  Copyright © 2022 Stripe. All rights reserved.
//

import UIKit

import StripeConnections

import StripeApplePay

class USBankAccountConnectionsExampleViewController: UIViewController {
    @objc weak var delegate: ExampleViewControllerDelegate?
    var inProgress: Bool = false {
        didSet {
            navigationController?.navigationBar.isUserInteractionEnabled = !inProgress
            payButton.isEnabled = !inProgress
            linkBankAccountButton.isEnabled = !inProgress
            inProgress
                ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
            fieldsStackView.isUserInteractionEnabled = !inProgress
        }
    }

    let bankAccountCollector = STPBankAccountCollector()
    var clientSecret: String? = nil

    // UI
    lazy var nameField: UITextField = {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.borderStyle = .roundedRect
        textField.placeholder = "Name"
        textField.delegate = self
        return textField
    }()
    lazy var emailField: UITextField = {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.borderStyle = .roundedRect
        textField.placeholder = "Email"
        textField.delegate = self
        return textField
    }()

    lazy var linkBankAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ Add bank account", for: .normal)
        button.addTarget(self, action: #selector(didTapLinkBankAccountButton), for: .touchUpInside)
        return button
    }()

    lazy var bankAccountLabel: UILabel = UILabel()

    lazy var fieldsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            nameField,
            emailField,
            linkBankAccountButton,
            bankAccountLabel,
        ])
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
        title = "US Bank Account with Connections"
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

        linkBankAccountButton.isEnabled = false
        payButton.isEnabled = false

        let constraints = [
            fieldsStackView.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1),
            fieldsStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: fieldsStackView.trailingAnchor, multiplier: 1),

            emailField.widthAnchor.constraint(equalTo: fieldsStackView.widthAnchor),
            nameField.widthAnchor.constraint(equalTo: fieldsStackView.widthAnchor),
            linkBankAccountButton.widthAnchor.constraint(equalTo: fieldsStackView.widthAnchor),
            bankAccountLabel.widthAnchor.constraint(equalTo: fieldsStackView.widthAnchor),

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

    @objc func didTapLinkBankAccountButton() {
        guard let name = nameField.text else {
            assertionFailure("Button shouldn't be enabled without name")
            return
        }
        payButton.isEnabled = false
        inProgress = true
        // 1. Create a US Bank Account PaymentIntent
        MyAPIClient.shared().createPaymentIntent(
            completion: { [self] (result, clientSecret, error) in
                guard let clientSecret = clientSecret else {
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
                    return
                }

                let collectParams = STPCollectBankAccountParams.collectUSBankAccountParams(with: name, email: emailField.text)

                bankAccountCollector.collectBankAccountForPayment(clientSecret: clientSecret,
                                                                  params: collectParams,
                                                                  from: self) { paymentIntent, collectError in
                    guard let paymentIntent = paymentIntent else {
                        self.delegate?.exampleViewController(self, didFinishWithError: collectError)
                        return
                    }
                    if paymentIntent.status == .requiresPaymentMethod {
                        // user canceled
                        self.delegate?.exampleViewController(self, didFinishWithMessage: "User canceled")
                    } else if paymentIntent.status == .requiresConfirmation {
                        inProgress = false
                        payButton.isEnabled = true
                        if let bankDetails = paymentIntent.paymentMethod?.usBankAccount {
                            bankAccountLabel.text = bankDetails.bankName + " ending in " + bankDetails.last4
                        } else {
                            assertionFailure("Should have us bank account details")
                            bankAccountLabel.text = "US Bank Account"
                        }
                        self.clientSecret = paymentIntent.clientSecret
                    } else {
                        self.delegate?.exampleViewController(self, didFinishWithMessage: "Unexpected PaymentIntent status \(String(describing: paymentIntent.status))")
                    }

                }
            }, additionalParameters: "supported_payment_methods=us_bank_account")
    }

}

extension USBankAccountConnectionsExampleViewController {
    @objc func pay() {

        guard let clientSecret = clientSecret else {
            assertionFailure("Shouldn't have pay enabled without valid clientSecret")
            return
        }
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret, paymentMethodType: .USBankAccount)
        paymentIntentParams.returnURL = "payments-example://stripe/"
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
    }
}

extension USBankAccountConnectionsExampleViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        self
    }
}

extension USBankAccountConnectionsExampleViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let updatedString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        if textField == nameField {
            linkBankAccountButton.isEnabled = !(updatedString?.isEmpty ?? true)
        }
        return true
    }

}
