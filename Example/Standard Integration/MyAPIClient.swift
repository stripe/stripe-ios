//
//  BackendAPIAdapter.swift
//  Standard Integration
//
//  Created by Ben Guo on 4/15/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Foundation
import Stripe

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

        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                let secret = json?["secret"] as? String else {
                completion(nil, error)
                return
            }
            completion(secret, nil)
        })
        task.resume()
    }

    func confirmPaymentIntent(_ paymentIntent: STPPaymentIntent, completion: @escaping ((_ clientSecret: String?, _ error: Error?)->Void)) {
        let url = self.baseURL.appendingPathComponent("confirm_payment")
        let params: [String: Any] = ["payment_intent_id": paymentIntent.stripeId]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                let secret = json?["secret"] as? String else {
                completion(nil, error)
                return
            }
            completion(secret, nil)
        })
        task.resume()
    }

    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL.appendingPathComponent("ephemeral_keys")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "api_version", value: apiVersion)]
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                completion(nil, error)
                return
            }
            completion(json, nil)
        })
        task.resume()
    }

}
