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
        let presenter = STPPaymentPresenter(checkoutOptions: options, delegate: self)
        presenter.requestPaymentFromPresentingViewController(self)
    }
    
    func paymentPresenter(presenter: STPPaymentPresenter!, didCreateStripeToken token: STPToken!, completion: STPTokenSubmissionHandler!) {
        if (parseApplicationId == "" || parseClientKey == "") {
            let userInfo : [NSObject: AnyObject] = [NSLocalizedDescriptionKey: "You created a token! Its value is \(token.tokenId). Now, you need to configure your Parse backend in order to charge this customer."]
            let error = NSError(domain: StripeDomain, code: STPErrorCode.STPInvalidRequestError.rawValue, userInfo: userInfo)
            completion(STPBackendChargeResult.Failure, error)
            return
        }
        let chargeParams = ["token": token.tokenId, "currency": "usd", "amount": 1000]
        Parse.setApplicationId(parseApplicationId, clientKey: parseClientKey)
        PFCloud.callFunctionInBackground("charge", withParameters: chargeParams) { (object, error) -> Void in
            if error != nil {
                completion(STPBackendChargeResult.Failure, error)
            }
            else {
                completion(STPBackendChargeResult.Success, nil)
            }
        }
    }
    
    func paymentPresenter(presenter: STPPaymentPresenter!, didFinishWithStatus status: STPPaymentStatus, error: NSError!) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            if error != nil {
                alert.title = "Something went wrong."
                alert.message = error.localizedDescription
            }
            if status == STPPaymentStatus.Success {
                alert.title = "Yay!"
                alert.message = "Your shirt's in the mail!"
            }
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }

}

