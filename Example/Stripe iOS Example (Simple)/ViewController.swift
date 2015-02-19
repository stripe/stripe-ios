//
//  ViewController.swift
//  Stripe iOS Exampe (Simple)
//
//  Created by Jack Flintermann on 1/15/15.
//  Copyright (c) 2015 Stripe. All rights reserved.
//

import UIKit
import Stripe

class ViewController: UIViewController, STPPaymentPresenterDelegate {

    // Replace these values with your application's keys
    let stripePublishableKey = ""
    let parseApplicationId = ""
    let parseClientKey = ""
    let appleMerchantId = ""
    
    let shirtPrice : UInt = 1000 // this is in cents
    
    @IBAction func beginPayment(sender: AnyObject) {
        if (stripePublishableKey == "") {
            let alert = UIAlertController(
                title: "You need to set your Stripe publishable key.",
                message: "You can find your publishable key at https://dashboard.stripe.com/account/apikeys .",
                preferredStyle: UIAlertControllerStyle.Alert
            )
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        let options = STPCheckoutOptions()
        options.publishableKey = stripePublishableKey
        if (appleMerchantId != "") {
            options.appleMerchantId = appleMerchantId
        }
        options.companyName = "Shirt Shop"
        options.purchaseDescription = "Cool Shirt"
        options.purchaseAmount = shirtPrice
        options.logoColor = UIColor.purpleColor()
        let presenter = STPPaymentPresenter(checkoutOptions: options, delegate: self)
        presenter.requestPaymentFromPresentingViewController(self)
    }
    
    func paymentPresenter(presenter: STPPaymentPresenter!, didCreateStripeToken token: STPToken!, completion: STPTokenSubmissionHandler!) {
        createBackendChargeWithToken(token, completion: completion)
    }
    
    func paymentPresenter(presenter: STPPaymentPresenter!, didFinishWithStatus status: STPPaymentStatus, error: NSError!) {
        self.dismissViewControllerAnimated(true, completion: {
            switch(status) {
            case .UserCancelled:
                return // just do nothing in this case
            case .Success:
                println("great success!")
            case .Error:
                println("oh no, an error: \(error.localizedDescription)")
            }
        })
    }
    
    // This is optional, and used to customize the line items shown on the Apple Pay sheet.
    func paymentPresenter(presenter: STPPaymentPresenter!, didPreparePaymentRequest request: PKPaymentRequest!) -> PKPaymentRequest! {
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Cool Shirt", amount: NSDecimalNumber(string: "10.00")),
            PKPaymentSummaryItem(label: "Free shipping", amount: NSDecimalNumber(string: "0.00"))
        ]
        return request
    }
    
    func createBackendChargeWithToken(token: STPToken, completion: STPTokenSubmissionHandler) {
        if (parseApplicationId == "" || parseClientKey == "") {
            let userInfo : [NSObject: AnyObject] = [NSLocalizedDescriptionKey: "You created a token! Its value is \(token.tokenId). Now, you need to configure your Parse backend in order to charge this customer."]
            let error = NSError(domain: StripeDomain, code: STPErrorCode.STPInvalidRequestError.rawValue, userInfo: userInfo)
            completion(STPBackendChargeResult.Failure, error)
            return
        }
        let chargeParams : [NSObject : AnyObject] = ["token": token.tokenId, "currency": "usd", "amount": shirtPrice]
        Parse.setApplicationId(parseApplicationId, clientKey: parseClientKey)
        PFCloud.callFunctionInBackground("charge", withParameters: chargeParams) { (_, error) -> Void in
            if error != nil {
                completion(STPBackendChargeResult.Failure, error)
            }
            else {
                completion(STPBackendChargeResult.Success, nil)
            }
        }
    }
}

