//
//  CheckoutViewController.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit
import Stripe

class CheckoutViewController: UIViewController, STPPaymentContextDelegate {

    // 1) To get started with this demo, first head to https://dashboard.stripe.com/account/apikeys
    // and copy your "Test Publishable Key" (it looks like pk_test_abcdef) into the line below.
    let stripePublishableKey = ""
    
    // 2) Next, optionally, to have this demo save your user's payment details, head to
    // https://github.com/stripe/example-ios-backend , click "Deploy to Heroku", and follow
    // the instructions (don't worry, it's free). Replace nil on the line below with your
    // Heroku URL (it looks like https://blazing-sunrise-1234.herokuapp.com ).
    let backendBaseURL: String? = nil

    // 3) Optionally, to enable Apple Pay, follow the instructions at https://stripe.com/docs/mobile/apple-pay
    // to create an Apple Merchant ID. Replace nil on the line below with it (it looks like merchant.com.yourappname).
    let appleMerchantID: String? = nil
    
    // These values will be shown to the user when they purchase with Apple Pay.
    let companyName = "Emoji Apparel"
    let paymentCurrency = "usd"

    let paymentContext: STPPaymentContext

    let theme: STPTheme
    let paymentRow: CheckoutRowView
    let totalRow: CheckoutRowView
    let buyButton: BuyButton
    let rowHeight: CGFloat = 44
    let productImage = UILabel()
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    var product = ""
    var paymentInProgress: Bool = false {
        didSet {
            UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseIn, animations: {
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

    init(product: String, price: Int, settings: Settings) {
        self.product = product
        self.productImage.text = product
        self.theme = settings.theme
        self.paymentRow = CheckoutRowView(title: "Payment", detail: "Select Payment",
                                          theme: settings.theme)
        self.totalRow = CheckoutRowView(title: "Total", detail: "", tappable: false,
                                        theme: settings.theme)
        self.buyButton = BuyButton(enabled: true, theme: settings.theme)
        MyAPIClient.sharedClient.baseURLString = self.backendBaseURL

        // This code is included here for the sake of readability, but in your application you should set up your configuration and theme earlier, preferably in your App Delegate.
        let config = STPPaymentConfiguration.sharedConfiguration()
        config.publishableKey = self.stripePublishableKey
        config.appleMerchantIdentifier = self.appleMerchantID
        config.companyName = self.companyName
        config.requiredBillingAddressFields = settings.requiredBillingAddressFields
        config.additionalPaymentMethods = settings.additionalPaymentMethods
        config.smsAutofillDisabled = !settings.smsAutofillEnabled
        
        let paymentContext = STPPaymentContext(APIAdapter: MyAPIClient.sharedClient,
                                               configuration: config,
                                               theme: settings.theme)
        let userInformation = STPUserInformation()
        paymentContext.prefilledInformation = userInformation
        
        paymentContext.paymentAmount = price
        paymentContext.paymentCurrency = self.paymentCurrency
        
        self.paymentContext = paymentContext
        super.init(nibName: nil, bundle: nil)
        self.paymentContext.delegate = self
        paymentContext.hostViewController = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = self.theme.primaryBackgroundColor
        var red: CGFloat = 0
        self.theme.primaryBackgroundColor.getRed(&red, green: nil, blue: nil, alpha: nil)
        self.activityIndicator.activityIndicatorViewStyle = red < 0.5 ? .White : .Gray
        self.navigationItem.title = "Emoji Apparel"

        self.productImage.font = UIFont.systemFontOfSize(70)
        self.view.addSubview(self.totalRow)
        self.view.addSubview(self.paymentRow)
        self.view.addSubview(self.productImage)
        self.view.addSubview(self.buyButton)
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.alpha = 0
        self.buyButton.addTarget(self, action: #selector(didTapBuy), forControlEvents: .TouchUpInside)
        self.totalRow.detail = "$\(self.paymentContext.paymentAmount/100).00"
        self.paymentRow.onTap = { [weak self] _ in
            self?.paymentContext.pushPaymentMethodsViewController()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = CGRectGetWidth(self.view.bounds)
        self.productImage.sizeToFit()
        self.productImage.center = CGPointMake(width/2.0,
                                               CGRectGetHeight(self.productImage.bounds)/2.0 + rowHeight)
        self.paymentRow.frame = CGRectMake(0, CGRectGetMaxY(self.productImage.frame) + rowHeight,
                                           width, rowHeight)
        self.totalRow.frame = CGRectMake(0, CGRectGetMaxY(self.paymentRow.frame),
                                         width, rowHeight)
        self.buyButton.frame = CGRectMake(0, 0, 88, 44)
        self.buyButton.center = CGPointMake(width/2.0, CGRectGetMaxY(self.totalRow.frame) + rowHeight*1.5)
        self.activityIndicator.center = self.buyButton.center
    }

    func didTapBuy() {
        self.paymentInProgress = true
        self.paymentContext.requestPayment()
    }
    
    func paymentContext(paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: STPErrorBlock) {
        MyAPIClient.sharedClient.completeCharge(paymentResult, amount: self.paymentContext.paymentAmount,
                                                completion: completion)
    }
    
    func paymentContext(paymentContext: STPPaymentContext, didFinishWithStatus status: STPPaymentStatus, error: NSError?) {
        self.paymentInProgress = false
        let title: String
        let message: String
        switch status {
        case .Error:
            title = "Error"
            message = error?.localizedDescription ?? ""
        case .Success:
            title = "Success"
            message = "You bought a \(self.product)!"
        case .UserCancellation:
            return
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(action)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    // MARK: STPPaymentContextDelegate

    func paymentContextDidChange(paymentContext: STPPaymentContext) {
        self.paymentRow.loading = paymentContext.loading
        if let paymentMethod = paymentContext.selectedPaymentMethod {
            self.paymentRow.detail = paymentMethod.label
        }
        else {
            self.paymentRow.detail = "Select Payment"
        }
    }

    func paymentContext(paymentContext: STPPaymentContext, didFailToLoadWithError error: NSError) {
        let alertController = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .Alert
        )
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
            self.navigationController?.popViewControllerAnimated(true)
        })
        let retry = UIAlertAction(title: "Retry", style: .Default, handler: { action in
            self.paymentContext.retryLoading()
        })
        alertController.addAction(cancel)
        alertController.addAction(retry)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

}
