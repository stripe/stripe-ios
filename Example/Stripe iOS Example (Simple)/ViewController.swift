//
//  ViewController.swift
//  Stripe iOS Exampe (Simple)
//
//  Created by Jack Flintermann on 1/15/15.
//  Copyright (c) 2015 Stripe. All rights reserved.
//

import UIKit
import PassKit
import Stripe

enum STPBackendChargeResult {
    case Success, Failure
}

typealias STPTokenSubmissionHandler = (STPBackendChargeResult?, NSError?) -> Void

class ViewController: UIViewController {
    
    required init?(coder aDecoder: NSCoder) {
        Stripe.setDefaultPublishableKey("pk_test_4TDXAGLdZFGNbXYGajQlcstU")
        let tokenDict = [
            "id":"foo",
            "livemode":true,
            "created":123,
            "card": [
                "id": "abc_123",
                "last4": "4242",
                "brand": "visa",
                "exp_month": 11,
                "exp_year": 17
            ]
        ]
        let token = STPToken.decodedObjectFromAPIResponse(tokenDict)!
        let apiAdapter = BackendAPIAdapter()
        apiAdapter.addToken(token, completion: { (_, _, _) in
        })
        let apiClient = STPAPIClient.sharedClient()
        let paymentContext = STPPaymentContext(APIAdapter: apiAdapter, supportedPaymentMethods: .All)
        paymentContext.appleMerchantIdentifier = "merchant.com.stripe.shop"
        paymentContext.paymentAmount = 1000
        paymentContext.apiClient = apiClient
        paymentContext.requiredBillingAddressFields = .Full
        self.paymentContext = paymentContext
        super.init(coder: aDecoder)
    }

    // Replace these values with your application's keys
    
    // Find this at https://dashboard.stripe.com/account/apikeys
    let stripePublishableKey = ""
    
    // To set this up, see https://github.com/stripe/example-ios-backend
    let backendChargeURLString = ""
    
    // To set this up, see https://stripe.com/docs/mobile/apple-pay
    let appleMerchantId = ""
    
    let paymentContext: STPPaymentContext
    
    @IBAction func enterCardDetails(sender: AnyObject) {
        let sourceList = STPPaymentMethodsViewController(paymentContext: paymentContext) { paymentMethod in
            self.navigationController?.popViewControllerAnimated(true)
        }
        self.navigationController?.pushViewController(sourceList, animated: true)
    }
    
    @IBAction func beginPayment(sender: AnyObject) {
        paymentContext.requestPaymentFromViewController(
            self,
            sourceHandler: { (_, _, completion) in
                completion(nil)
            }, completion: { (status, error) in
                switch status {
                case .Error: print(error)
                case .Success: print("success")
                case .UserCancellation: print("cancelled")
                }
            }
        )
    }
}

