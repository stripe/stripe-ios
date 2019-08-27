//
//  CheckoutViewController.swift
//  Standard Integration
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit
import Stripe

class CheckoutViewController: UIViewController, STPPaymentContextDelegate {

    // 1) To get started with this demo, first head to https://dashboard.stripe.com/account/apikeys
    // and copy your "Test Publishable Key" (it looks like pk_test_abcdef) into the line below.
    var stripePublishableKey = ""

    // 2) Next, optionally, to have this demo save your user's payment details, head to
    // https://github.com/stripe/example-ios-backend/tree/v16.0.0, click "Deploy to Heroku", and follow
    // the instructions (don't worry, it's free). Replace nil on the line below with your
    // Heroku URL (it looks like https://blazing-sunrise-1234.herokuapp.com ).
    var backendBaseURL: String? = nil

    // 3) Optionally, to enable Apple Pay, follow the instructions at https://stripe.com/docs/mobile/apple-pay
    // to create an Apple Merchant ID. Replace nil on the line below with it (it looks like merchant.com.yourappname).
    var appleMerchantID: String? = ""

    // These values will be shown to the user when they purchase with Apple Pay.
    let companyName = "Emoji Apparel"
    let paymentCurrency = "usd"

    let paymentContext: STPPaymentContext

    let theme: STPTheme
    let tableView: UITableView
    let paymentRow: CheckoutRowView
    let shippingRow: CheckoutRowView?
    let totalRow: CheckoutRowView
    let buyButton: BuyButton
    let rowHeight: CGFloat = 52
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    let numberFormatter: NumberFormatter
    var products: [Product]
    var paymentInProgress: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                if self.paymentInProgress {
                    self.activityIndicator.startAnimating()
                    self.activityIndicator.alpha = 1
                    self.buyButton.alpha = 0
                }
                else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.alpha = 0
                    self.buyButton.alpha = 1
                }
            }, completion: nil)
        }
    }
    
    init(products: [Product], settings: Settings) {
        if let stripePublishableKey = UserDefaults.standard.string(forKey: "StripePublishableKey") {
            self.stripePublishableKey = stripePublishableKey
        }
        if let backendBaseURL = UserDefaults.standard.string(forKey: "StripeBackendBaseURL") {
            self.backendBaseURL = backendBaseURL
        }
        let stripePublishableKey = self.stripePublishableKey
        let backendBaseURL = self.backendBaseURL

        assert(stripePublishableKey.hasPrefix("pk_"), "You must set your Stripe publishable key at the top of CheckoutViewController.swift to run this app.")
        assert(backendBaseURL != nil, "You must set your backend base url at the top of CheckoutViewController.swift to run this app.")

        self.products = products
        self.theme = settings.theme
        MyAPIClient.sharedClient.baseURLString = self.backendBaseURL

        // This code is included here for the sake of readability, but in your application you should set up your configuration and theme earlier, preferably in your App Delegate.
        let config = STPPaymentConfiguration.shared()
        config.publishableKey = self.stripePublishableKey
        config.appleMerchantIdentifier = self.appleMerchantID
        config.companyName = self.companyName
        config.requiredBillingAddressFields = settings.requiredBillingAddressFields
        config.requiredShippingAddressFields = settings.requiredShippingAddressFields
        config.shippingType = settings.shippingType
        config.additionalPaymentOptions = settings.additionalPaymentOptions

        let customerContext = STPCustomerContext(keyProvider: MyAPIClient.sharedClient)
        let paymentContext = STPPaymentContext(customerContext: customerContext,
                                               configuration: config,
                                               theme: settings.theme)
        let userInformation = STPUserInformation()
        paymentContext.prefilledInformation = userInformation
        paymentContext.paymentAmount = products.reduce(0) { result, product in
            return result + product.price
        }
        paymentContext.paymentCurrency = self.paymentCurrency

        self.tableView = UITableView()

        let paymentSelectionFooter = PaymentContextFooterView(text:
            """
The sample backend attaches some test cards:

• 4242 4242 4242 4242
    A default VISA card.

• 4000 0000 0000 3220
    Use this to test 3D Secure 2 authentication.

See https://stripe.com/docs/testing.
""")
        paymentSelectionFooter.theme = settings.theme
        paymentContext.paymentOptionsViewControllerFooterView = paymentSelectionFooter

        let addCardFooter = PaymentContextFooterView(text: "You can add custom footer views to the add card screen.")
        addCardFooter.theme = settings.theme
        paymentContext.addCardViewControllerFooterView = addCardFooter

        self.paymentContext = paymentContext

        self.paymentRow = CheckoutRowView(title: "Pay from", detail: "Select payment method")
        if let requiredFields = config.requiredShippingAddressFields, !requiredFields.isEmpty {
            var shippingString = "Contact"
            if requiredFields.contains(.postalAddress) {
                shippingString = config.shippingType == .shipping ? "Ship to" : "Deliver to"
            }
            self.shippingRow = CheckoutRowView(title: shippingString,
                                               detail: "Select address")
        } else {
            self.shippingRow = nil
        }
        self.totalRow = CheckoutRowView(title: "Total", detail: "", tappable: false)
        self.buyButton = BuyButton(enabled: false, title: "Buy")
        var localeComponents: [String: String] = [
            NSLocale.Key.currencyCode.rawValue: self.paymentCurrency,
        ]
        localeComponents[NSLocale.Key.languageCode.rawValue] = NSLocale.preferredLanguages.first
        let localeID = NSLocale.localeIdentifier(fromComponents: localeComponents)
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: localeID)
        numberFormatter.numberStyle = .currency
        numberFormatter.usesGroupingSeparator = true
        self.numberFormatter = numberFormatter
        super.init(nibName: nil, bundle: nil)
        self.paymentContext.delegate = self
        paymentContext.hostViewController = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        self.tableView.backgroundColor = .white
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = .systemBackground
            self.tableView.backgroundColor = .systemBackground
        }
        #endif
        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = 84
        self.tableView.register(EmojiCheckoutCell.self, forCellReuseIdentifier: "Cell")
        var red: CGFloat = 0
        
        self.theme.primaryBackgroundColor.getRed(&red, green: nil, blue: nil, alpha: nil)
        self.activityIndicator.activityIndicatorViewStyle = red < 0.5 ? .white : .gray
        self.navigationItem.title = "Checkout"

        // Footer
        let makeSeparatorView: () -> UIView = {
            let view = UIView()
            view.backgroundColor = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)
            #if canImport(CryptoKit)
            if #available(iOS 13.0, *) {
                view.backgroundColor = UIColor.systemGray5
            }
            #endif
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.heightAnchor.constraint(equalToConstant: 1),
                ])
            return view
        }
        let spacerView = UIView()
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        spacerView.heightAnchor.constraint(equalToConstant: BuyButton.defaultHeight + 8).isActive = true
        let footerContainerView = UIStackView(arrangedSubviews: [shippingRow, makeSeparatorView(), paymentRow, makeSeparatorView(), totalRow, spacerView].compactMap({ $0 }))
        footerContainerView.axis = .vertical
        footerContainerView.frame = CGRect(x: 0, y: 0, width: 0, height: footerContainerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height)

        self.activityIndicator.alpha = 0
        self.buyButton.addTarget(self, action: #selector(didTapBuy), for: .touchUpInside)
        self.totalRow.detail = self.numberFormatter.string(from: NSNumber(value: Float(self.paymentContext.paymentAmount)/100))!
        self.paymentRow.onTap = { [weak self] in
            self?.paymentContext.pushPaymentOptionsViewController()
        }
        self.shippingRow?.onTap = { [weak self]  in
            self?.paymentContext.pushShippingViewController()
        }
        
        // Layout
        for view in [tableView as UIView, totalRow, paymentRow, shippingRow, buyButton, activityIndicator] {
            view?.translatesAutoresizingMaskIntoConstraints = false
        }
        self.view.addSubview(tableView)
        self.view.addSubview(self.buyButton)
        self.view.addSubview(self.activityIndicator)
        tableView.tableFooterView = footerContainerView
        
        let topAnchor, bottomAnchor: NSLayoutYAxisAnchor
        let leadingAnchor, trailingAnchor: NSLayoutXAxisAnchor
        if #available(iOS 11.0, *) {
            topAnchor = view.safeAreaLayoutGuide.topAnchor
            bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
            leadingAnchor = view.safeAreaLayoutGuide.leadingAnchor
            trailingAnchor = view.safeAreaLayoutGuide.trailingAnchor
        } else {
            topAnchor = view.topAnchor
            bottomAnchor = view.bottomAnchor
            leadingAnchor = view.leadingAnchor
            trailingAnchor = view.trailingAnchor
        }
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),

            buyButton.heightAnchor.constraint(equalToConstant: BuyButton.defaultHeight),
            buyButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            buyButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            buyButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            activityIndicator.centerXAnchor.constraint(equalTo: buyButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: buyButton.centerYAnchor),
            ])
    }

    @objc func didTapBuy() {
        self.paymentInProgress = true
        self.paymentContext.requestPayment()
    }

    // MARK: STPPaymentContextDelegate

    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {
        MyAPIClient.sharedClient.createAndConfirmPaymentIntent(paymentResult,
                                                               amount: self.paymentContext.paymentAmount,
                                                               returnURL: "payments-example://stripe-redirect",
                                                               shippingAddress: self.paymentContext.shippingAddress,
                                                               shippingMethod: self.paymentContext.selectedShippingMethod) { (clientSecret, error) in
                                                                guard let clientSecret = clientSecret else {
                                                                    completion(.error, error ?? NSError(domain: StripeDomain, code: 123, userInfo: [NSLocalizedDescriptionKey: "Unable to parse clientSecret from response"]))
                                                                    return
                                                                }
                                                                STPPaymentHandler.shared().handleNextAction(forPayment: clientSecret, authenticationContext: paymentContext, returnURL: "payments-example://stripe-redirect") { (status, handledPaymentIntent, actionError) in
                                                                    switch (status) {
                                                                    case .succeeded:
                                                                        guard let handledPaymentIntent = handledPaymentIntent else {
                                                                            completion(.error, actionError ?? NSError(domain: StripeDomain, code: 123, userInfo: [NSLocalizedDescriptionKey: "Unknown failure"]))
                                                                            return
                                                                        }
                                                                        if (handledPaymentIntent.status == .requiresConfirmation) {
                                                                            // Confirm again on the backend
                                                                            MyAPIClient.sharedClient.confirmPaymentIntent(handledPaymentIntent) { clientSecret, error in
                                                                                guard let clientSecret = clientSecret else {
                                                                                    completion(.error, error ?? NSError(domain: StripeDomain, code: 123, userInfo: [NSLocalizedDescriptionKey: "Unable to parse clientSecret from response"]))
                                                                                    return
                                                                                }
                                                                                
                                                                                // Retrieve the Payment Intent and check the status for success
                                                                                STPAPIClient.shared().retrievePaymentIntent(withClientSecret: clientSecret) { (paymentIntent, retrieveError) in
                                                                                    guard let paymentIntent = paymentIntent else {
                                                                                        completion(.error, retrieveError ?? NSError(domain: StripeDomain, code: 123, userInfo: [NSLocalizedDescriptionKey: "Unable to parse payment intent from response"]))
                                                                                        return
                                                                                    }
                                                                                    
                                                                                    if paymentIntent.status == .succeeded {
                                                                                        completion(.success, nil)
                                                                                    }
                                                                                    else {
                                                                                        completion(.error, NSError(domain: StripeDomain, code: 123, userInfo: [NSLocalizedDescriptionKey: "Authentication failed."]))
                                                                                    }
                                                                                }
                                                                            }
                                                                        } else {
                                                                            // Success
                                                                            completion(.success, nil)
                                                                        }
                                                                    case .failed:
                                                                        completion(.error, actionError)
                                                                    case .canceled:
                                                                        completion(.userCancellation, nil)
                                                                    }
                                                                }
        }
    }

    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        self.paymentInProgress = false
        let title: String
        let message: String
        switch status {
        case .error:
            title = "Error"
            message = error?.localizedDescription ?? ""
        case .success:
            title = "Success"
            message = "Your purchase was successful!"
        case .userCancellation:
            return
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }

    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        self.paymentRow.loading = paymentContext.loading
        if let paymentOption = paymentContext.selectedPaymentOption {
            self.paymentRow.detail = paymentOption.label
        }
        else {
            self.paymentRow.detail = "Select Payment"
        }
        if let shippingMethod = paymentContext.selectedShippingMethod {
            self.shippingRow?.detail = shippingMethod.label
        }
        else {
            self.shippingRow?.detail = "Select address"
        }
        self.totalRow.detail = self.numberFormatter.string(from: NSNumber(value: Float(self.paymentContext.paymentAmount)/100))!
        buyButton.isEnabled = paymentContext.selectedPaymentOption != nil && (paymentContext.selectedShippingMethod != nil || self.shippingRow == nil)
    }

    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        let alertController = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            // Need to assign to _ because optional binding loses @discardableResult value
            // https://bugs.swift.org/browse/SR-1681
            _ = self.navigationController?.popViewController(animated: true)
        })
        let retry = UIAlertAction(title: "Retry", style: .default, handler: { action in
            self.paymentContext.retryLoading()
        })
        alertController.addAction(cancel)
        alertController.addAction(retry)
        self.present(alertController, animated: true, completion: nil)
    }

    // Note: this delegate method is optional. If you do not need to collect a
    // shipping method from your user, you should not implement this method.
    func paymentContext(_ paymentContext: STPPaymentContext, didUpdateShippingAddress address: STPAddress, completion: @escaping STPShippingMethodsCompletionBlock) {
        let upsGround = PKShippingMethod()
        upsGround.amount = 0
        upsGround.label = "UPS Ground"
        upsGround.detail = "Arrives in 3-5 days"
        upsGround.identifier = "ups_ground"
        let upsWorldwide = PKShippingMethod()
        upsWorldwide.amount = 10.99
        upsWorldwide.label = "UPS Worldwide Express"
        upsWorldwide.detail = "Arrives in 1-3 days"
        upsWorldwide.identifier = "ups_worldwide"
        let fedEx = PKShippingMethod()
        fedEx.amount = 5.99
        fedEx.label = "FedEx"
        fedEx.detail = "Arrives tomorrow"
        fedEx.identifier = "fedex"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if address.country == nil || address.country == "US" {
                completion(.valid, nil, [upsGround, fedEx], fedEx)
            }
            else if address.country == "AQ" {
                let error = NSError(domain: "ShippingError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Invalid Shipping Address",
                                                                                   NSLocalizedFailureReasonErrorKey: "We can't ship to this country."])
                completion(.invalid, error, nil, nil)
            }
            else {
                fedEx.amount = 20.99
                completion(.valid, nil, [upsWorldwide, fedEx], fedEx)
            }
        }
    }

}

// MARK: - UITableViewController
extension CheckoutViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? EmojiCheckoutCell else {
            return UITableViewCell()
        }
        
        let product = self.products[indexPath.item]
        cell.configure(with: product)
        cell.selectionStyle = .none
        return cell
    }
}
