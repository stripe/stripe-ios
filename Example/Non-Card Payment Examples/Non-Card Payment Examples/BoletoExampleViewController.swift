//
//  BoletoExampleViewController.swift
//  Non-Card Payment Examples
//
//  Created by Ramon Torres on 9/2/21.
//  Copyright © 2021 Stripe. All rights reserved.
//

import UIKit
import Stripe

class BoletoExampleViewController: UIViewController {

    @objc weak var delegate: ExampleViewControllerDelegate?

    private lazy var nameField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.textContentType = .name
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .next
        field.delegate = self
        field.text = "Jane Diaz"
        return field
    }()

    private lazy var emailField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.textContentType = .emailAddress
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .next
        field.delegate = self
        field.text = "jane@example.com"
        return field
    }()

    private lazy var taxIDField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.keyboardType = .numberPad
        field.autocorrectionType = .no
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .next
        field.delegate = self
        field.text = "00.000.000/0001-91"
        return field
    }()

    private lazy var addressField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.textContentType = .streetAddressLine1
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .next
        field.delegate = self
        field.text = "Av. Do Brasil 1374"
        return field
    }()

    private lazy var cityField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.textContentType = .addressCity
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .next
        field.delegate = self
        field.text = "São Paulo"
        return field
    }()

    private lazy var stateField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.autocorrectionType = .no
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .next
        field.delegate = self
        field.text = "SP"
        return field
    }()

    private lazy var postalCodeField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.textContentType = .postalCode
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .done
        field.delegate = self
        field.text = "01310100"
        return field
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    private lazy var submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Pay with Boleto", for: [])
        button.addTarget(self, action: #selector(pay), for: .touchUpInside)
        return button
    }()

    private lazy var allFields: [(String, UITextField)] = [
        ("Name", nameField),
        ("Email address", emailField),
        ("CPF/CNPJ", taxIDField),
        ("Address", addressField),
        ("City", cityField),
        ("State", stateField),
        ("Postal code", postalCodeField)
    ]

    private let scrollView: UIScrollView = {
        let scrollView = KeyboardAvoidingScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 20, leading: 20, bottom: 20, trailing: 20)
        return stackView
    }()

    private var isLoading: Bool = false {
        didSet {
            if isLoading {
                activityIndicator.startAnimating()
                submitButton.isHidden = true
            } else {
                activityIndicator.stopAnimating()
                submitButton.isHidden = false
            }
        }
    }

    var apiClient = MyAPIClient.shared()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Boleto"

        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        for (title, field) in allFields {
            let titleLabel = UILabel()
            titleLabel.font = UIFont.preferredFont(forTextStyle: .callout)
            titleLabel.text = title
            titleLabel.translatesAutoresizingMaskIntoConstraints = false

            let fieldContainer = UIStackView(arrangedSubviews: [titleLabel, field])
            fieldContainer.axis = .vertical
            fieldContainer.spacing = 4
            fieldContainer.translatesAutoresizingMaskIntoConstraints = false

            stackView.addArrangedSubview(fieldContainer)

            NSLayoutConstraint.activate([
                fieldContainer.leadingAnchor.constraint(equalTo: stackView.layoutMarginsGuide.leadingAnchor),
                fieldContainer.trailingAnchor.constraint(equalTo: stackView.layoutMarginsGuide.trailingAnchor)
            ])
        }

        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(submitButton)
    }

}

extension BoletoExampleViewController {
    @objc func pay() {
        view.endEditing(true)

        let boletoParams = STPPaymentMethodBoletoParams()
        boletoParams.taxID = taxIDField.text

        let address = STPPaymentMethodAddress()
        address.line1 = addressField.text
        address.city = cityField.text
        address.state = stateField.text
        address.postalCode = postalCodeField.text
        address.country = "BR"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = nameField.text
        billingDetails.email = emailField.text
        billingDetails.address = address

        let paymentMethodParams = STPPaymentMethodParams(
            boleto: boletoParams,
            billingDetails: billingDetails,
            metadata: nil
        )

        isLoading = true

        apiClient.createPaymentIntent(
            completion: { (_, clientSecret, error) in
                guard let clientSecret = clientSecret else {
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
                    return
                }

                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodParams = paymentMethodParams

                STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: self) { (status, _, error) in
                    switch status {
                    case .failed:
                        self.delegate?.exampleViewController(
                            self,
                            didFinishWithMessage: "Payment failed. \(String(describing: error?.localizedDescription))"
                        )
                    case .canceled:
                        self.delegate?.exampleViewController(self, didFinishWithMessage: "Canceled")
                    case .succeeded:
                        self.delegate?.exampleViewController(
                            self,
                            didFinishWithMessage: "Your order was received and is awaiting payment confirmation."
                        )
                    @unknown default:
                        fatalError()
                    }

                    self.isLoading = false
                }
            },
            additionalParameters: "country=br&supported_payment_methods=boleto"
        )
    }
}

extension BoletoExampleViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextField = findField(after: textField) {
            nextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }

        return true
    }

    private func findField(after currentField: UITextField) -> UITextField? {
        let fields = allFields.map { (_, field) in field }

        if let index = fields.firstIndex(of: currentField), index + 1 < fields.count {
            return fields[index + 1]
        }

        return nil
    }
}

// MARK: -
extension BoletoExampleViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        self
    }
}
