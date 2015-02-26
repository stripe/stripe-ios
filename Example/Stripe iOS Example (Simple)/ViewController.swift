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
    let backendChargeURLString = ""
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
            PKPaymentSummaryItem(label: "Stripe Shop", amount: NSDecimalNumber(string: "5.00"))
        ]
        return request
    }
    
    func createBackendChargeWithToken(token: STPToken, completion: STPTokenSubmissionHandler) {
        if backendChargeURLString != "" {
            if let url = NSURL(string: backendChargeURLString) {
                let chargeParams : [String: AnyObject] = ["stripeToken": token.tokenId, "amount": shirtPrice]
                request(.POST, url, parameters: chargeParams)
                    .responseJSON { (_, response, _, error) in
                        if response?.statusCode == 200 {
                            completion(STPBackendChargeResult.Success, nil)
                        } else {
                            completion(STPBackendChargeResult.Failure, error)
                        }
                }
                return
            }
        }
        completion(STPBackendChargeResult.Failure, nil)
    }
}

