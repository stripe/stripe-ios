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
    let stripePublishableKey = "<#stripePublishableKey#>"
    
    // 2a) Next, optionally, to have this demo save your user's payment details, head to
    // https://github.com/stripe/example-ios-backend , click "Deploy to Heroku", and follow
    // the instructions (don't worry, it's free). Replace nil on the line below with your
    // Heroku URL (it looks like https://blazing-sunrise-1234.herokuapp.com ).
    let backendBaseURL: String? = nil
    
    // 2b) If you're saving your user's payment details, head to https://dashboard.stripe.com/test/customers ,
    // click "New", and create a customer (you can leave the fields blank). Replace nil on the line below
    // with the newly-created customer ID (it looks like cus_abcdef).
    let customerID: String? = nil
    
    // 3) Optionally, to enable Apple Pay, follow the instructions at https://stripe.com/docs/mobile/apple-pay
    // to create an Apple Merchant ID. Replace nil on the line below with it (it looks like merchant.com.yourappname).
    let appleMerchantID: String? = nil
    
    // These values will be shown to the user when they purchase with Apple Pay.
    let merchantName = "Emoji Apparel"
    let paymentAmount = 1000 // this amount is in cents.
    let paymentCurrency = "usd"

    let myAPIClient: MyAPIClient
    let paymentContext: STPPaymentContext
    let products = ["👕", "👖", "👗", "👞", "👟", "👠", "👡", "👢",
                    "👒", "👙", "💄", "🎩", "👛", "👜", "🕶", "👚"]
    let checkoutView = CheckoutView()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        Stripe.setDefaultPublishableKey(self.stripePublishableKey)
        self.myAPIClient = MyAPIClient(baseURL: self.backendBaseURL,
                                     customerID: self.customerID)
        let paymentContext = STPPaymentContext(APIAdapter: self.myAPIClient)
        paymentContext.appleMerchantIdentifier = self.appleMerchantID
        paymentContext.paymentAmount = self.paymentAmount
        paymentContext.paymentCurrency = self.paymentCurrency
        paymentContext.merchantName = self.merchantName
        paymentContext.requiredBillingAddressFields = .Zip
        self.paymentContext = paymentContext
        super.init(nibName: nil, bundle: nil)
        self.paymentContext.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = self.checkoutView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let index = Int(arc4random_uniform(UInt32(self.products.count)))
        self.checkoutView.product = self.products[index]
        self.navigationController?.navigationBar.translucent = false
        self.navigationItem.title = "Emoji Apparel"
        self.checkoutView.buyButton.addTarget(self, action: #selector(didTapBuy), forControlEvents: .TouchUpInside)
        self.checkoutView.totalRow.detail = "$10.00"
        self.checkoutView.paymentRow.onTap = { _ in
            guard self.checkConstants() else { return }

            if let navController = self.navigationController {
                self.paymentContext.pushPaymentMethodsViewControllerOntoNavigationController(navController)
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        guard self.checkConstants() else { return }

        self.paymentContext.didAppear()
    }

    func didTapBuy() {
        guard self.checkConstants() else { return }

        self.checkoutView.paymentInProgress = true
        self.paymentContext.requestPaymentFromViewController(
            self,
            sourceHandler: { (paymentMethod, source, completion) in
                self.createBackendCharge(source, completion: completion)
            }, completion: { (status, error) in
                self.checkoutView.paymentInProgress = false
                let title: String
                let message: String
                switch status {
                case .Error:
                    title = "Error"
                    message = error?.localizedDescription ?? ""
                case .Success:
                    title = "Success"
                    message = "You bought a \(self.checkoutView.product)!"
                case .UserCancellation:
                    return
                }
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alertController.addAction(action)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        )
    }

    func createBackendCharge(source: STPSource, completion: STPErrorBlock) {
        self.myAPIClient.completeCharge(source, amount: self.paymentAmount, completion: completion)
    }

    // MARK: STPPaymentContextDelegate

    func paymentContextDidChange(paymentContext: STPPaymentContext) {
        self.checkoutView.buyButton.enabled = paymentContext.isReadyForPayment()
        if let paymentMethod = paymentContext.selectedPaymentMethod {
            self.checkoutView.paymentRow.detail = paymentMethod.label
        }
        else {
            self.checkoutView.paymentRow.detail = "Select Payment"
        }
    }

    func paymentContextDidBeginLoading(paymentContext: STPPaymentContext) {
        self.checkoutView.paymentRow.loading = true
    }

    func paymentContextDidEndLoading(paymentContext: STPPaymentContext) {
        self.checkoutView.paymentRow.loading = false
    }

    func paymentContext(paymentContext: STPPaymentContext, didFailToLoadWithError error: NSError) {
        let alertController = UIAlertController(
            title: "Error Retrieving Cards",
            message: error.localizedDescription,
            preferredStyle: .Alert
        )
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(action)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    func checkConstants() -> Bool {
        if self.stripePublishableKey.containsString("#")
            || self.stripePublishableKey.utf16.count == 0 {
            let alertController = UIAlertController(title: "No Stripe Publishable Key",
                                                    message: "Please set stripePublishableKey to your account's test publishable key in CheckoutViewController.swift",
                                                    preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(action)
            self.presentViewController(alertController, animated: true, completion: nil)
            return false
        }
        return true
    }

}
