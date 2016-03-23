//
//  ViewController.swift
//  Stripe iOS Exampe (Simple)
//
//  Created by Jack Flintermann on 1/15/15.
//  Copyright (c) 2015 Stripe. All rights reserved.
//

import UIKit
import Stripe

enum STPBackendChargeResult {
    case Success, Failure
}

typealias STPTokenSubmissionHandler = (STPBackendChargeResult?, NSError?) -> Void


class ViewController: UIViewController, STPPaymentAuthorizationViewControllerDelegate {

    // Replace these values with your application's keys
    
    // Find this at https://dashboard.stripe.com/account/apikeys
    let stripePublishableKey = ""
    
    // To set this up, see https://github.com/stripe/example-ios-backend
    let backendChargeURLString = ""
    
    // To set this up, see https://stripe.com/docs/mobile/apple-pay
    let appleMerchantId = ""
    
    let shirtPrice : UInt = 1000 // this is in cents
    
    @IBAction func beginPayment(sender: AnyObject) {
        Stripe.setDefaultPublishableKey("pk_test_4TDXAGLdZFGNbXYGajQlcstU")
        let paymentRequest = STPPaymentRequest(appleMerchantId: "woo")
        paymentRequest.lineItems = [
            STPLineItem(label: "food", amount: NSDecimalNumber(string: "10.00"))
        ]
        let paymentAuth = STPPaymentAuthorizationViewController(paymentRequest: paymentRequest)
        paymentAuth.delegate = self
        self.presentViewController(paymentAuth, animated: true, completion: nil)
    }
    
    func paymentAuthorizationViewControllerDidCancel(paymentAuthorizationViewController: STPPaymentAuthorizationViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func paymentAuthorizationViewController(paymentAuthorizationViewController: STPPaymentAuthorizationViewController, didFailWithError error: NSError) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func paymentAuthorizationViewController(paymentAuthorizationViewController: STPPaymentAuthorizationViewController, didCreateCheckoutResult result: STPPaymentResult) {
        dismissViewControllerAnimated(true, completion: nil)
    }

//    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: ((PKPaymentAuthorizationStatus) -> Void)) {
//        let apiClient = STPAPIClient(publishableKey: stripePublishableKey)
//        apiClient.createTokenWithPayment(payment, completion: { (token, error) -> Void in
//            if error == nil {
//                if let token = token {
//                    self.createBackendChargeWithToken(token, completion: { (result, error) -> Void in
//                        if result == STPBackendChargeResult.Success {
//                            completion(PKPaymentAuthorizationStatus.Success)
//                        }
//                        else {
//                            completion(PKPaymentAuthorizationStatus.Failure)
//                        }
//                    })
//                }
//            }
//            else {
//                completion(PKPaymentAuthorizationStatus.Failure)
//            }
//        })
//    }
//
//    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
//        dismissViewControllerAnimated(true, completion: nil)
//    }
//    
//    func createBackendChargeWithToken(token: STPToken, completion: STPTokenSubmissionHandler) {
//        if backendChargeURLString != "" {
//            if let url = NSURL(string: backendChargeURLString  + "/charge") {
//                
//                let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
//                let request = NSMutableURLRequest(URL: url)
//                request.HTTPMethod = "POST"
//                let postBody = "stripeToken=\(token.tokenId)&amount=\(shirtPrice)"
//                let postData = postBody.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
//                session.uploadTaskWithRequest(request, fromData: postData, completionHandler: { data, response, error in
//                    let successfulResponse = (response as? NSHTTPURLResponse)?.statusCode == 200
//                    if successfulResponse && error == nil {
//                        completion(.Success, nil)
//                    } else {
//                        if error != nil {
//                            completion(.Failure, error)
//                        } else {
//                            completion(.Failure, NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "There was an error communicating with your payment backend."]))
//                        }
//                        
//                    }
//                }).resume()
//                
//                return
//            }
//        }
//        completion(STPBackendChargeResult.Failure, NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "You created a token! Its value is \(token.tokenId). Now configure your backend to accept this token and complete a charge."]))
//    }
}

