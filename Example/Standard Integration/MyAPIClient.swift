//
//  BackendAPIAdapter.swift
//  Standard Integration
//
//  Created by Ben Guo on 4/15/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Foundation
import Stripe
import Alamofire

class MyAPIClient: NSObject, STPCustomerEphemeralKeyProvider {

    static let sharedClient = MyAPIClient()
    var baseURLString: String? = nil
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }

    func createAndConfirmPaymentIntent(_ result: STPPaymentResult,
                                       amount: Int,
                                       returnURL: String,
                                       shippingAddress: STPAddress?,
                                       shippingMethod: PKShippingMethod?,
                                       completion: @escaping ((_ clientSecret: String?, _ error: Error?)->Void)) {
        let url = self.baseURL.appendingPathComponent("capture_payment")
        var params: [String: Any] = [
            "payment_method": result.paymentMethod.stripeId,
            "amount": amount,
            "return_url": returnURL,
            "metadata": [
                // example-ios-backend allows passing metadata through to Stripe
                "payment_request_id": "B3E611D1-5FA1-4410-9CEC-00958A5126CB",
            ],
            ]
        params["shipping"] = STPAddress.shippingInfoForCharge(with: shippingAddress, shippingMethod: shippingMethod)
        Alamofire.request(url, method: .post, parameters: params)
            .validate(statusCode: 200..<300)
            .responseJSON(completionHandler: { (response) in
                switch response.result {
                case .success(let json):
                    completion((json as? [String: AnyObject])?["secret"] as? String, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            })
    }

    func confirmPaymentIntent(_ paymentIntent: STPPaymentIntent, completion: @escaping ((_ clientSecret: String?, _ error: Error?)->Void)) {
        let url = self.baseURL.appendingPathComponent("confirm_payment")
        let params: [String: Any] = ["payment_intent_id": paymentIntent.stripeId]
        Alamofire.request(url, method: .post, parameters: params)
            .validate(statusCode: 200..<300)
            .responseJSON(completionHandler: { (response) in
                switch response.result {
                case .success(let json):
                    completion((json as? [String: AnyObject])?["secret"] as? String, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            })
    }

    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL.appendingPathComponent("ephemeral_keys")
        Alamofire.request(url, method: .post, parameters: [
            "api_version": apiVersion,
            ])
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    completion(json as? [String: AnyObject], nil)
                case .failure(let error):
                    completion(nil, error)
                }
        }
    }

}
